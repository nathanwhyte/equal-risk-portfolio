require "test_helper"

class TickersControllerTest < ActionDispatch::IntegrationTest
  # Disable parallel execution for these tests since they rely on shared cache state
  parallelize(workers: 1)

  setup do
    @portfolio = portfolios(:one)
    @user = users(:one)
    sign_in_as(@user)
    # Clear cache before each test to ensure clean state
    Rails.cache.clear

    # Stub Polygon API for search tests
    stub_request(:get, /api\.polygon\.io\/v3\/reference\/tickers/)
      .with(query: hash_including("apiKey"))
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

    put tickers_add_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" }
    }, as: :turbo_stream

    assert_response :success

    # Verify ticker was added to the correct cache
    cache_key = "tickers:new:#{session_id}"
    cached_tickers = Rails.cache.read(cache_key) || []
    assert cached_tickers.any? { |t| t.symbol == "TSLA" }, "Ticker should be in new cache"
  end

  test "add ticker uses edit cache when portfolio_id provided" do
    get edit_portfolio_url(@portfolio)
    session_id = session[:session_id]

    put tickers_add_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" },
      portfolio_id: @portfolio.id
    }, as: :turbo_stream

    assert_response :success

    # Verify ticker was added to the correct cache
    cache_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"
    cached_tickers = Rails.cache.read(cache_key) || []
    assert cached_tickers.any? { |t| t.symbol == "TSLA" }, "Ticker should be in portfolio-specific cache"
  end

  test "remove ticker removes from correct cache" do
    get new_portfolio_url
    session_id = session[:session_id]

    # First add a ticker
    put tickers_add_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" }
    }, as: :turbo_stream

    # Verify it's there
    cache_key = "tickers:new:#{session_id}"
    cached_tickers = Rails.cache.read(cache_key) || []
    assert cached_tickers.any? { |t| t.symbol == "TSLA" }

    # Now remove it
    put tickers_remove_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" }
    }, as: :turbo_stream

    assert_response :success

    # Verify it's gone
    cached_tickers = Rails.cache.read(cache_key) || []
    assert_not cached_tickers.any? { |t| t.symbol == "TSLA" }, "Ticker should be removed from cache"
  end

  test "search passes portfolio_id to controller" do
    get new_portfolio_url

    post tickers_search_path, params: {
      query: "AAPL",
      portfolio_id: @portfolio.id
    }, as: :turbo_stream

    assert_response :success
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

    begin
      get new_portfolio_url
      session_id = session[:session_id]

      # Add different tickers to each portfolio cache
      put tickers_add_path, params: {
        ticker: { symbol: "AAPL", name: "Apple" },
        portfolio_id: @portfolio.id
      }, as: :turbo_stream

      put tickers_add_path, params: {
        ticker: { symbol: "GOOGL", name: "Google" },
        portfolio_id: portfolio_two.id
      }, as: :turbo_stream

      # Verify isolation
      cache_key_one = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"
      cache_key_two = "tickers:edit:#{session_id}:portfolio_#{portfolio_two.id}"

      cached_one = Rails.cache.read(cache_key_one) || []
      cached_two = Rails.cache.read(cache_key_two) || []

      assert cached_one.any? { |t| t.symbol == "AAPL" }, "Portfolio one should have AAPL"
      assert_not cached_one.any? { |t| t.symbol == "GOOGL" }, "Portfolio one should not have GOOGL"

      assert cached_two.any? { |t| t.symbol == "GOOGL" }, "Portfolio two should have GOOGL"
      assert_not cached_two.any? { |t| t.symbol == "AAPL" }, "Portfolio two should not have AAPL"
    ensure
      portfolio_two.destroy
    end
  end

  test "portfolio_id_param helper returns nil when not present" do
    put tickers_add_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" }
    }, as: :turbo_stream

    controller = @controller
    assert_nil controller.send(:portfolio_id_param)
  end

  test "portfolio_id_param helper returns portfolio_id when present" do
    put tickers_add_path, params: {
      ticker: { symbol: "AAPL", name: "Apple" },
      portfolio_id: @portfolio.id
    }, as: :turbo_stream

    controller = @controller
    assert_equal @portfolio.id.to_s, controller.send(:portfolio_id_param)
  end
end
