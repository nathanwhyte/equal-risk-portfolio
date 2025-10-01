class Search::TickersController < ApplicationController
  def search
    if params[:query].present?
      @tickers = polygon_search(params[:query])
    else
      @tickers = []
    end
  end

  private

  def polygon_search(query)
    key = Rails.application.credentials.dig(:polygon, :api_key)

    response = generate_polygon_search_url(query, key)
    if response.success?
      res = response.parsed_response["results"]
      stocks = res.map do |stock|
        {
          id: stock["composite_figi"],
          ticker: stock["ticker"],
          name: stock["name"]
        }
      end

      return stocks
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
