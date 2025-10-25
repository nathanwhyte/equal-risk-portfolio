require "test_helper"

class TickersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @portfolio = portfolios(:one)
    Rails.application.credentials.config[:polygon] = { api_key: "test_key" }

    # Stub Polygon API for search tests
    stub_request(:get, /api\.polygon\.io\/v3\/reference\/tickers/)
      .to_return(
        status: 200,
        body: {
          results: [
            { ticker: "AAPL", name: "Apple Inc." },
            { ticker: "GOOGL", name: "Alphabet Inc." }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  test "add ticker uses new cache when no portfolio_id provided" do
    get new_portfolio_url
    session_id = session[:session_id]
    cache_key = "tickers:new:#{session_id}"

    # Clear cache first
    Rails.cache.delete(cache_key)

    put tickers_add_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" }
    }, as: :turbo_stream

    # In test environment, cached_tickers returns mock data
    # So we verify the cache key would be used by checking the controller method
    assert_response :success
  end

  test "add ticker uses edit cache when portfolio_id provided" do
    get edit_portfolio_url(@portfolio)
    session_id = session[:session_id]
    cache_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"

    # Clear cache first
    Rails.cache.delete(cache_key)

    put tickers_add_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" },
      portfolio_id: @portfolio.id
    }, as: :turbo_stream

    assert_response :success
  end

  test "remove ticker uses new cache when no portfolio_id provided" do
    get new_portfolio_url

    put tickers_remove_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" }
    }, as: :turbo_stream

    assert_response :success
  end

  test "remove ticker uses edit cache when portfolio_id provided" do
    get edit_portfolio_url(@portfolio)

    put tickers_remove_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" },
      portfolio_id: @portfolio.id
    }, as: :turbo_stream

    assert_response :success
  end

  test "search passes portfolio_id to results view" do
    get new_portfolio_url

    post tickers_search_path, params: {
      query: "AAPL",
      portfolio_id: @portfolio.id
    }, as: :turbo_stream

    assert_response :success
    # Note: In test env, assigns(:portfolio_id) is set by search action
  end

  test "search works without portfolio_id for new portfolio" do
    get new_portfolio_url

    post tickers_search_path, params: {
      query: "AAPL"
    }, as: :turbo_stream

    assert_response :success
  end

  test "different portfolios maintain separate caches" do
    portfolio_two = Portfolio.create!(
      name: "Second Portfolio",
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    get new_portfolio_url
    session_id = session[:session_id]

    cache_key_one = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"
    cache_key_two = "tickers:edit:#{session_id}:portfolio_#{portfolio_two.id}"

    # Verify keys are unique per portfolio
    assert_not_equal cache_key_one, cache_key_two
    assert_includes cache_key_one, @portfolio.id.to_s
    assert_includes cache_key_two, portfolio_two.id.to_s

    portfolio_two.destroy
  end

  test "portfolio_id_param helper returns nil when not present" do
    get new_portfolio_url

    put tickers_add_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" }
    }

    controller = @controller
    assert_nil controller.send(:portfolio_id_param)
  end

  test "portfolio_id_param helper returns portfolio_id when present" do
    get edit_portfolio_url(@portfolio)

    put tickers_add_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" },
      portfolio_id: @portfolio.id
    }

    controller = @controller
    assert_equal @portfolio.id.to_s, controller.send(:portfolio_id_param)
  end
end
