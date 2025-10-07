class SearchController < ApplicationController
  def tickers
    if params[:query].present?
      @results = polygon_search(params[:query])
    else
      @results = []
    end

    # convert to fetch from cache
    @portfolio = Portfolio.find(params[:portfolio_id])
    render partial: "results", locals: { items: @results, portfolio: @portfolio }
  end

  def selected
    @portfolio = Portfolio.find(params[:portfolio_id])
    @portfolio.tickers = params[:tickers].split(",")
    render partial: "portfolios/selected_tickers", locals: { portfolio: @portfolio }
  end

  private

  def polygon_search(query)
    key = Rails.application.credentials.dig(:polygon, :api_key)

    response = generate_polygon_search_url(query, key)
    if response.success?
      res = response.parsed_response["results"]
      results = res.map do |stock|
        {
          id: stock["id"],
          ticker: stock["ticker"],
          name: stock["name"]
        }
      end

      return results
    end

    []
  end

  def generate_polygon_search_url(query, key)
    HTTParty.get("https://api.polygon.io/v3/reference/tickers",
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
  end
end
