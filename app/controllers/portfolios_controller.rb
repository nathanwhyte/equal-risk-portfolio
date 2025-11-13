class PortfoliosController < ApplicationController
  include PortfolioAllocations
  include PortfolioCapAndRedistributeOptions
  include PortfolioHelper

  helper PortfolioDisplayHelper
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  def index
    @portfolios = Portfolio.all.order(created_at: :asc)
  end

  def show
    # Check if there's an active cap and redistribute option
    active_option = @portfolio.active_cap_and_redistribute_option

    if active_option&.has_weights?
      # Use portfolio tickers and weights from the active option
      raw_tickers = @portfolio.tickers || []
      raw_weights = active_option.weights
      @viewing_cap_and_redistribute_option = active_option
    else
      # Load tickers and weights directly from portfolio
      raw_tickers = @portfolio.tickers || []
      raw_weights = @portfolio.weights || {}
      @viewing_cap_and_redistribute_option = nil
    end

    @tickers = tickers_from_hash(raw_tickers)
    @weights = raw_weights || {}
    @allocations = @portfolio.allocations
    @adjusted_weights = WeightCalculator.new(
      weights: @weights,
      allocations: @allocations
    ).adjusted_weights

    Rails.logger.info @portfolio.pretty_print
  end

  def new
    @portfolio = Portfolio.new
    @tickers = cached_tickers(mode: :new)
    @count = cached_tickers(mode: :new).length
  end

  def new_copy
    @original_portfolio = Portfolio.includes(:allocations, :cap_and_redistribute_options).find(params[:id])

    write_cached_tickers(
      tickers_from_hash(@original_portfolio.tickers),
      mode: :new_copy,
      original_portfolio_id: @original_portfolio.id
    )

    @tickers = cached_tickers(mode: :new_copy, original_portfolio_id: @original_portfolio.id)
    @count = cached_tickers(mode: :new_copy, original_portfolio_id: @original_portfolio.id).length
    @copy_portfolio = Portfolio.new(
      copy_of_id: @original_portfolio.id,
      name: "Copy of #{@original_portfolio.name}"
    )
  end

  def create
    @portfolio = Portfolio.new

    @portfolio.name = params[:portfolio][:name]

    # Determine cache mode based on whether this is a copy
    cache_mode = params[:copy_of_id].present? ? :new_copy : :new
    original_portfolio_id = params[:copy_of_id]

    tickers = cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id)
    ticker_symbols = tickers.map(&:symbol)
    tickers_hash = tickers_to_hash(tickers)

    if ticker_symbols.length <= 0
      @portfolio.errors.add(:tickers, "must include at least one ticker")
      @tickers = cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id)
      @count = cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id).length
      render cache_mode == :new_copy ? :new_copy : :new, status: :unprocessable_entity
      return
    end

    begin
      @portfolio.weights = math_engine_client.calculate_weights(
        tickers: ticker_symbols
      )
    rescue MathEngineClient::Error => e
      Rails.logger.error "API call failed: #{e.message}"
      @portfolio.errors.add(:base, "There was a problem creating the portfolio. Please try again.")
      @tickers = cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id)
      @count = cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id).length
      render cache_mode == :new_copy ? :new_copy : :new, status: :unprocessable_entity
      return
    end

    # Set tickers in hash format for storage
    @portfolio.tickers = tickers_hash

    if params[:copy_of_id].present?
      original_portfolio = Portfolio.includes(:allocations, :cap_and_redistribute_options).find_by(id: params[:copy_of_id])
      if original_portfolio
        @portfolio.copy_of = original_portfolio
        @portfolio.allocations = copy_allocations_from(original_portfolio)
        @portfolio.cap_and_redistribute_options = copy_cap_and_redistribute_options_from(original_portfolio)
      end
    end

    Rails.logger.info @portfolio.pretty_print

    if params[:commit] == "Search"
      redirect_to tickers_search_path(query: params[:query])
    else
      if @portfolio.save
        redirect_to @portfolio, notice: "Portfolio was successfully created."
      else
        @tickers = cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id)
        @count = cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id).length
        render cache_mode == :new_copy ? :new_copy : :new, status: :unprocessable_entity
      end
    end

    clear_cached_tickers(mode: cache_mode, original_portfolio_id: original_portfolio_id)
  end

  def edit
    # Load tickers from portfolio
    tickers = tickers_from_hash(@portfolio.tickers)
    write_cached_tickers(tickers, mode: :edit, portfolio_id: @portfolio.id)
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

    # Handle cap and redistribute options updates (toggle, remove, add)
    # Check both top-level and nested params (form_with nests, button_to doesn't)
    if params[:update_cap_and_redistribute_options] == "true" || params.dig(:portfolio, :update_cap_and_redistribute_options) == "true"
      handle_cap_and_redistribute_options_update
      return
    end

    Rails.logger.info "\nUpdating Portfolio (#{params})\n"

    if params[:cap_and_redistribute] == "true" || params.dig(:portfolio, :cap_and_redistribute) == "true"
      cap_percentage = params.dig(:portfolio, :cap_percentage).to_f
      top_n = params.dig(:portfolio, :top_n).to_i

      new_option = @portfolio.cap_and_redistribute_options.create!(
        cap_percentage: cap_percentage / 100.0,
        top_n: top_n,
        active: false
      )

      # Mark the new option as active and deactivate all others
      new_option.activate!

      handle_cap_and_redistribute(@portfolio.tickers, cap_percentage, top_n)
      return
    end

    # Handle regular portfolio updates from the edit page
    tickers = cached_tickers(mode: :edit, portfolio_id: @portfolio.id)
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

    # Convert tickers to hash format for storage
    tickers_hash = tickers_to_hash(tickers)

    # Update portfolio with new values
    @portfolio.tickers = tickers_hash
    @portfolio.weights = new_weights

    if @portfolio.save
      redirect_to @portfolio, notice: "Portfolio was successfully updated."
    else
      @tickers = tickers
      @count = tickers.length
      render :edit, status: :unprocessable_entity
    end

    clear_cached_tickers(mode: :edit, portfolio_id: @portfolio.id)
  end

  def destroy
    @portfolio.destroy
    redirect_to portfolios_url, notice: "Portfolio was successfully destroyed."
  end

  private

  def set_portfolio
    @portfolio = Portfolio.includes(:cap_and_redistribute_options).find(params.expect(:id))
  end

  def portfolio_params
    params.expect(portfolio: [ :name, :tickers, :allocations ])
  end

  def handle_cap_and_redistribute(tickers, cap_percentage, top_n)
    Rails.logger.info "\nApplying cap and redistribute: Cap #{cap_percentage}%, Top N #{top_n}, tickers: #{tickers}\n"

    version_cap = cap_percentage > 0 ? cap_percentage / 100.0 : nil
    version_top_n = top_n > 0 ? top_n : nil

    raw_tickers = @portfolio.tickers || []
    tickers_arr = Array(raw_tickers)
    tickers_list = tickers_arr.map { |ticker| ticker["symbol"] || ticker[:symbol] }

    new_weights = math_engine_client.calculate_weights(
      tickers: tickers_list,
      cap: version_cap,
      top_n: version_top_n
    )
    tickers_hash = tickers_arr.map do |ticker|
      {
        "symbol" => ticker["symbol"] || ticker[:symbol],
        "name" => ticker["name"] || ticker[:name]
      }
    end

    save_succeeded = false
    Portfolio.transaction do
      # Update portfolio with new values
      @portfolio.tickers = tickers_hash
      @portfolio.weights = new_weights

      # Update the active cap and redistribute option with the calculated weights
      active_option = @portfolio.active_cap_and_redistribute_option
      if active_option
        active_option.update!(weights: new_weights)
      end

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
      raw_tickers = @portfolio.tickers || []
      raw_weights = @portfolio.weights || {}
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
