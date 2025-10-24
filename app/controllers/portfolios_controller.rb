class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: %i[ show ]

  def index
    @portfolios = Portfolio.all
  end

  def show
    @tickers = @portfolio.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name:  ticker["name"]) }

    Rails.logger.info "\n\nPortfolio #{@portfolio.name} with tickers #{@portfolio.tickers.map { |ticker| ticker["symbol"] }} and weights #{@portfolio.weights}\n\n"
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

    @portfolio.weights = call_math_engine(ticker_symbols)

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

  private

  def set_portfolio
    @portfolio = Portfolio.find(params.expect(:id))
  end

  def portfolio_params
    params.expect(portfolio: [ :name, :tickers ])
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
