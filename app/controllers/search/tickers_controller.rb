class Search::TickersController < ApplicationController
  def search
    # TODO: update to call Polygon
    #       pass back logo url, ticker, and name
    tickers = %w[AAPL MSFT GOOGL AMZN TSLA]
    if params[:query].present?
      @tickers = tickers.select { |ticker| ticker.include?(params[:query].upcase) }
    else
      @tickers = []
    end
  end
end
