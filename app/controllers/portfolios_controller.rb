class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  def index
    @portfolios = Portfolio.all
  end

  def show
    @tickers = @portfolio.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name:  ticker["name"]) }

    if !@portfolio.allocations.nil?
      allocation_sum = 0
      for allocation in @portfolio.allocations.values
        allocation_sum  += (allocation.to_f / 100.0)
      end

      allocation_adjustment = 1.0 - allocation_sum

      @portfolio.weights.each do |ticker, weight|
        @portfolio.weights[ticker] = weight * allocation_adjustment
      end
    end

    Rails.logger.info "\nPortfolio #{@portfolio.name} with tickers #{@portfolio.tickers.map { |ticker| ticker["symbol"] }} and weights #{@portfolio.weights}\n"
  end

  def new
    @portfolio = Portfolio.new
    @tickers = cached_tickers
    @count = cached_tickers.length
  end

  def create
    @portfolio = Portfolio.new

    @portfolio.name = params[:portfolio][:name]
    @portfolio.tickers = cached_tickers

    ticker_symbols = @portfolio.tickers.map { |ticker| ticker["symbol"] }

    if ticker_symbols.length <= 0
      @portfolio.errors.add(:tickers, "must include at least one ticker")
      @tickers = cached_tickers
      @count = cached_tickers.length
      render :new, status: :unprocessable_entity
      return
    end

    begin
      @portfolio.weights = call_math_engine(ticker_symbols)
    rescue => e
      Rails.logger.error "API call failed: #{e.message}"
      @portfolio.errors.add(:base, "There was a problem creating the portfolio. Please try again.")
      @tickers = cached_tickers
      @count = cached_tickers.length
      render :new, status: :unprocessable_entity
      return
    end

    Rails.logger.info "\n\nPortfolio #{@portfolio.name} created with tickers #{@portfolio.tickers.map { |ticker| ticker["symbol"] }} and weights #{@portfolio.weights}\n\n"

    if params[:commit] == "Search"
      redirect_to tickers_search_path(query: params[:query])
    else
      if @portfolio.save
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
    tickers = @portfolio.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name:  ticker["name"]) }
    write_cached_tickers(tickers, @portfolio.id)
    @count = tickers.length
    @tickers = tickers
  end

  def update
    # Handle allocations-only updates from the show page
    # Check both top-level and nested params (form_with nests, button_to doesn't)
    if params[:update_allocations] == "true" || params.dig(:portfolio, :update_allocations) == "true"
      handle_allocations_update
      return
    end

    # Handle regular portfolio updates from the edit page
    tickers = cached_tickers(@portfolio.id)
    @portfolio.tickers = tickers
    @portfolio.name = portfolio_params[:name]

    begin
      @portfolio.weights = call_math_engine(tickers.map { |ticker| ticker.symbol })
    rescue => e
      Rails.logger.error "API call failed: #{e.message}"
      @portfolio.errors.add(:base, "There was a problem updating the portfolio. Please try again.")
      @tickers = tickers
      @count = tickers.length
      render :edit, status: :unprocessable_entity
      return
    end

    if @portfolio.save
      redirect_to @portfolio, notice: "Portfolio was successfully updated."
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

  def handle_allocations_update
    # Initialize allocations hash if nil
    current_allocations = @portfolio.allocations || {}
    new_allocations = current_allocations.dup

    # Handle removal
    if params[:remove_allocation].present?
      allocation_name = params[:remove_allocation]
      new_allocations = new_allocations.except(allocation_name)
    end

    # Handle addition
    if params[:allocation_name].present? && params[:allocation_weight].present?
      allocation_name = params[:allocation_name].strip
      allocation_weight = params[:allocation_weight].to_f

      if allocation_name.blank?
        @portfolio.errors.add(:allocations, "Allocation name cannot be blank")
      elsif allocation_weight <= 0 || allocation_weight > 100
        @portfolio.errors.add(:allocations, "Allocation weight must be between 0 and 100")
      else
        new_allocations[allocation_name] = allocation_weight
      end
    end

    # Assign the new allocations hash to trigger change detection
    @portfolio.allocations = new_allocations

    Rails.logger.info "Saving allocations: #{@portfolio.allocations.inspect}"

    if @portfolio.errors.empty? && @portfolio.save
      redirect_to @portfolio, notice: "Allocations were successfully updated."
    else
      Rails.logger.error "Failed to save allocations: #{@portfolio.errors.full_messages.inspect}"
      @tickers = @portfolio.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
      render :show, status: :unprocessable_entity
    end
  end

  def call_math_engine(tickers)
    body  = {
      tickers: tickers
    }.to_json

    response = HTTParty.post(
      "#{ENV["API_URL"]}/calculate",
      body: body,
      headers: {
        "Content-Type" => "application/json"
      }
    )

    Rails.logger.info "\n\nResponse from math engine: #{response.parsed_response}\n\n"

    unmapped_weights = response.parsed_response["weights"]

    weights  = {}
    unmapped_weights.map do |pair|
      weights[pair["ticker"]] = pair["weight"].to_f
    end

    weights
  end
end
