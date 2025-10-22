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
      query = params[:query].upcase
      @results = polygon_search(query)
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
    tickers = cached_tickers

    if tickers.nil? || tickers.empty?
      return false
    end

    tickers.find { |ticker| ticker.symbol == ticker_params[:symbol] }
  end

  def add_cached_ticker
    tickers = cached_tickers

    unless tickers.any? { |t| t.symbol == @ticker.symbol }
      tickers << Ticker.new(symbol: @ticker.symbol, name: @ticker.name)
    end

    write_cached_tickers(tickers)

    @count = tickers.length
  end

  def remove_cached_ticker
    tickers = cached_tickers

    ticker_to_remove = tickers.find { |ticker| ticker.symbol == ticker_params[:symbol] }

    if ticker_to_remove
      tickers.delete(ticker_to_remove)
      write_cached_tickers(tickers)
    end

    @count = tickers.length
  end

  def polygon_search(query)
    key = Rails.application.credentials.dig(:polygon, :api_key)

    response = HTTParty.get("https://api.polygon.io/v3/reference/tickers",
                            query: {
                              type: "CS",
                              market: "stocks",
                              ticker: query,
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
