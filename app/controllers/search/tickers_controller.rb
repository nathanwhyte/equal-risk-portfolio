class Search::TickersController < ApplicationController
  def search
    tickers = %w[AAPL MSFT GOOGL AMZN TSLA]
    if params[:query].present?
      @tickers = tickers.select { |ticker| ticker.include?(params[:query].upcase) }
    else
      @tickers = tickers
    end
  end
end
