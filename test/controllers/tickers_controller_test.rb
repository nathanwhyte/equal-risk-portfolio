require "test_helper"

class TickersControllerTest < ActionDispatch::IntegrationTest
  # Disable parallel execution for these tests since they rely on shared cache state
  parallelize(workers: 1)

  setup do
    @portfolio = portfolios(:one)
    @user = users(:one)
    sign_in_as(@user)
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

  test "add ticker to new portfolio cache" do
    get new_portfolio_url
    session_id = session[:session_id]

    put tickers_add_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" }
    }, as: :turbo_stream

    assert_response :success

    cache_key = "tickers:new:#{session_id}"
    cached_tickers = Rails.cache.read(cache_key) || []
    assert cached_tickers.any? { |t| t.symbol == "TSLA" }
  end

  test "add ticker to edit portfolio cache" do
    get edit_portfolio_url(@portfolio)
    session_id = session[:session_id]

    put tickers_add_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" },
      portfolio_id: @portfolio.id
    }, as: :turbo_stream

    assert_response :success

    cache_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"
    cached_tickers = Rails.cache.read(cache_key) || []
    assert cached_tickers.any? { |t| t.symbol == "TSLA" }
  end

  test "remove ticker from cache" do
    get new_portfolio_url
    session_id = session[:session_id]

    # Add ticker
    put tickers_add_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" }
    }, as: :turbo_stream

    # Remove ticker
    put tickers_remove_path, params: {
      ticker: { symbol: "TSLA", name: "Tesla" }
    }, as: :turbo_stream

    assert_response :success

    # Verify removed
    cache_key = "tickers:new:#{session_id}"
    cached_tickers = Rails.cache.read(cache_key) || []
    assert_not cached_tickers.any? { |t| t.symbol == "TSLA" }
  end

  test "search returns ticker results" do
    post tickers_search_path, params: {
      query: "AAPL"
    }, as: :turbo_stream

    assert_response :success
  end

  test "portfolios maintain separate ticker caches" do
    portfolio_two = Portfolio.create!(
      name: "Second Portfolio",
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    begin
      # Get session_id from a request
      get edit_portfolio_url(@portfolio)
      session_id = session[:session_id]

      # Add different tickers to each portfolio
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

      assert cached_one.any? { |t| t.symbol == "AAPL" }
      assert_not cached_one.any? { |t| t.symbol == "GOOGL" }

      assert cached_two.any? { |t| t.symbol == "GOOGL" }
      assert_not cached_two.any? { |t| t.symbol == "AAPL" }
    ensure
      portfolio_two.destroy
    end
  end
end
