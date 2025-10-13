class TickersController < ApplicationController
  def replace
    @ticker = Ticker.new(ticker_params)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def add
    @ticker = Ticker.new(ticker_params)

    if check_cached_ticker
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("ticker_#{@ticker.symbol}", partial: "tickers/ticker", locals: { ticker: @ticker })
        end
      end
    else

      add_cached_ticker

      respond_to do |format|
        format.turbo_stream
      end
    end
  end

  def remove
    @ticker = Ticker.new(ticker_params)

    remove_cached_ticker

    respond_to do |format|
      format.turbo_stream
    end
  end

  def search
    if params[:query].present?
      @results = polygon_search(params[:query])
    else
      @results = []
    end

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  private

  def ticker_params
    params.expect(ticker: [ :symbol, :name ])
  end

  def check_cached_ticker
    cached_tickers = session[:tickers]

    if cached_tickers.nil? || cached_tickers.empty?
      return false
    end

    cached_tickers.find { |ticker| ticker["symbol"] == ticker_params[:symbol] }
  end

  def add_cached_ticker
    cached_tickers = session[:tickers]

    ticker_hash = { "symbol" => @ticker.symbol, "name" => @ticker.name }

    unless cached_tickers.any? { |t| t["symbol"] == ticker_hash["symbol"] }
      cached_tickers << ticker_hash
    end

    session[:tickers] = cached_tickers

    @count = cached_tickers.length
  end

  def remove_cached_ticker
    cached_tickers = session[:tickers]

    ticker_to_remove = cached_tickers.find { |ticker| ticker["symbol"] == ticker_params[:symbol] }

    if ticker_to_remove
      cached_tickers.delete(ticker_to_remove)
      session[:tickers] = cached_tickers
    end

    @count = cached_tickers.length
  end

  def polygon_search(query)
    key = Rails.application.credentials.dig(:polygon, :api_key)

    response = HTTParty.get("https://api.polygon.io/v3/reference/tickers",
                 query: {
                   type: "CS",
                   market: "stocks",
                   search: query,
                   active: true,
                   order: "asc",
                   limit: 9,
                   sort: "ticker",
                   apiKey: key
                 })

    if response.success?
      res = response.parsed_response["results"]
      results = res.map do |stock|
        Ticker.new(symbol: stock["ticker"], name: stock["name"])
      end

      return results
    end

    []
  end
end
