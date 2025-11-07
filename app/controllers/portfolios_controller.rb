class PortfoliosController < ApplicationController
  include PortfolioVersions
  include PortfolioAllocations
  include PortfolioHelper

  helper PortfolioDisplayHelper
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  def index
    @portfolios = Portfolio.all
  end

  def show
    if params[:version_number].present?
      @viewing_version = load_portfolio_version(@portfolio, params[:version_number])

      unless @viewing_version
        redirect_to @portfolio, alert: "Version not found"
        return
      end

      raw_tickers, raw_weights = version_tickers_and_weights(@viewing_version)
    else
      raw_tickers, raw_weights, _latest = load_latest_version_data(@portfolio)
      @viewing_version = nil
    end

    @tickers = tickers_from_hash(raw_tickers)
    @weights = raw_weights || {}
    @allocations = @portfolio.allocations
    @adjusted_weights = WeightCalculator.new(
      weights: @weights,
      allocations: @allocations
    ).adjusted_weights

    Rails.logger.info "\nPortfolio #{@portfolio.name} with tickers #{@tickers.map(&:symbol)} and weights #{@weights}\n"
  end

  def new
    @portfolio = Portfolio.new
    @tickers = cached_tickers
    @count = cached_tickers.length
  end

  def create
    @portfolio = Portfolio.new

    @portfolio.name = params[:portfolio][:name]
    tickers = cached_tickers
    ticker_symbols = tickers.map(&:symbol)
    tickers_hash = tickers_to_hash(tickers)

    if ticker_symbols.length <= 0
      @portfolio.errors.add(:tickers, "must include at least one ticker")
      @tickers = cached_tickers
      @count = cached_tickers.length
      render :new, status: :unprocessable_entity
      return
    end

    begin
      @portfolio.weights = math_engine_client.calculate_weights(
        tickers: ticker_symbols
      )
    rescue MathEngineClient::Error => e
      Rails.logger.error "API call failed: #{e.message}"
      @portfolio.errors.add(:base, "There was a problem creating the portfolio. Please try again.")
      @tickers = cached_tickers
      @count = cached_tickers.length
      render :new, status: :unprocessable_entity
      return
    end

    # Set tickers in hash format for storage
    @portfolio.tickers = tickers_hash

    Rails.logger.info "\n\nPortfolio #{@portfolio.name} created with tickers #{ticker_symbols} and weights #{@portfolio.weights}\n\n"

    if params[:commit] == "Search"
      redirect_to tickers_search_path(query: params[:query])
    else
      if @portfolio.save
        @portfolio.create_initial_version
        redirect_to @portfolio, notice: "Portfolio was successfully created."
      else
        @tickers = cached_tickers
        @count = cached_tickers.length
        render :new, status: :unprocessable_entity
      end
    end

    clear_cached_tickers
  end

  def edit
    # Load tickers from latest version (or fallback to stored portfolio data)
    latest = @portfolio.latest_version
    tickers = if latest
      tickers_from_hash(latest.tickers)
    else
      tickers_from_hash(@portfolio.tickers)
    end
    write_cached_tickers(tickers, @portfolio.id)
    @count = tickers.length
    @tickers = tickers
  end

  def update
    Rails.logger.info "\nParams received for update: #{params}\n"

    # Handle allocations-only updates from the show page
    # Check both top-level and nested params (form_with nests, button_to doesn't)
    if params[:update_allocations] == "true" || params.dig(:portfolio, :update_allocations) == "true"
      handle_allocations_update
      return
    end

    Rails.logger.info "\nUpdating Portfolio #{params})\n"

    if params[:cap_and_redistribute] == "true" || params.dig(:portfolio, :cap_and_redistribute) == "true"
      handle_cap_and_redistribute(@portfolio.tickers,
        params.dig(:portfolio, :cap_percentage).to_f,
        params.dig(:portfolio, :top_n).to_i)
      return
    end

    # Handle regular portfolio updates from the edit page
    tickers = cached_tickers(@portfolio.id)
    @portfolio.name = portfolio_params[:name]

    # Calculate new weights before transaction
    begin
      new_weights = math_engine_client.calculate_weights(
        tickers: tickers.map(&:symbol)
      )
    rescue MathEngineClient::Error => e
      Rails.logger.error "API call failed: #{e.message}"
      @portfolio.errors.add(:base, "There was a problem updating the portfolio. Please try again.")
      @tickers = tickers
      @count = tickers.length
      render :edit, status: :unprocessable_entity
      return
    end

    # Convert tickers to hash format for version storage
    tickers_hash = tickers_to_hash(tickers)

    # Wrap version creation/update and portfolio update in a transaction for atomicity
    save_succeeded = false
    success_message = "Portfolio was successfully updated."
    Portfolio.transaction do
      # Check if this is a "Create New Version" request (from standalone version form)
      if params[:create_new_version] == "true" || params[:commit] == "Create New Version"
        # Extract version metadata from portfolio_version params
        version_params = params[:portfolio_version] || {}
        version_title = version_params[:title]&.strip.presence
        version_notes = version_params[:notes]&.strip.presence

        # Create a new version with the new tickers and weights
        @portfolio.create_new_version(
          tickers: tickers_hash,
          weights: new_weights,
          title: version_title,
          notes: version_notes
        )

        success_message = "New Version created, Portfolio successfully updated."
      else
        # "Update Current Version" - update the latest version instead of creating a new one
        @portfolio.update_latest_version(
          tickers: tickers_hash,
          weights: new_weights
        )
      end

      # Update portfolio table with new values (for backward compatibility/cache)
      @portfolio.tickers = tickers_hash
      @portfolio.weights = new_weights

      if @portfolio.save
        save_succeeded = true
      else
        raise ActiveRecord::Rollback
      end
    end

    # Check if save was successful
    if save_succeeded
      redirect_to @portfolio, notice: success_message
    else
      @tickers = tickers
      @count = tickers.length
      render :edit, status: :unprocessable_entity
    end

    clear_cached_tickers(@portfolio.id)
  end

  def destroy
    @portfolio.destroy
    redirect_to portfolios_url, notice: "Portfolio was successfully destroyed."
  end

  private

  def set_portfolio
    @portfolio = Portfolio.find(params.expect(:id))
  end

  def portfolio_params
    params.expect(portfolio: [ :name, :tickers, :allocations ])
  end

  def handle_cap_and_redistribute(tickers, cap_percentage, top_n)
    Rails.logger.info "\nApplying cap and redistribute: Cap #{cap_percentage}%, Top N #{top_n}, tickers: #{tickers}\n"

    version_cap = cap_percentage > 0 ? cap_percentage / 100.0 : nil
    version_top_n = top_n > 0 ? top_n : nil

    tickers_list = Array(tickers).map { |ticker| ticker["symbol"] || ticker[:symbol] }
    new_weights = math_engine_client.calculate_weights(
      tickers: tickers_list,
      cap: version_cap,
      top_n: version_top_n
    )
    tickers_hash = Array(tickers).map do |ticker|
      {
        "symbol" => ticker["symbol"] || ticker[:symbol],
        "name" => ticker["name"] || ticker[:name]
      }
    end

    save_succeeded = false
    Portfolio.transaction do
      version_title = "Cap #{cap_percentage}% to Top #{top_n}"
      version_notes = nil

      # Create a new version with the new tickers and weights
      @portfolio.create_new_version(
        tickers: tickers_hash,
        weights: new_weights,
        title: version_title,
        notes: version_notes,
        cap: version_cap,
        top_n: version_top_n
      )

      # Update portfolio table with new values (for backward compatibility/cache)
      @portfolio.tickers = tickers_hash
      @portfolio.weights = new_weights

      if @portfolio.save
        save_succeeded = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if save_succeeded
      redirect_to @portfolio, notice: "Cap and redistribute options were successfully applied."
    else
      Rails.logger.error "Failed to apply cap and redistribute options: #{@portfolio.errors.full_messages.inspect}"
      raw_tickers, raw_weights, @viewing_version = load_latest_version_data(@portfolio)
      @tickers = tickers_from_hash(raw_tickers)
      @weights = raw_weights || {}
      @allocations = @portfolio.allocations
      @adjusted_weights = WeightCalculator.new(
        weights: @weights,
        allocations: @allocations
      ).adjusted_weights

      render :show, status: :unprocessable_entity
    end
  end

  def math_engine_client
    @math_engine_client ||= MathEngineClient.new
  end
end
