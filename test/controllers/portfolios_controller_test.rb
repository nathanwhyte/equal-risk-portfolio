require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @portfolio = portfolios(:one)
    @user = users(:one)
    sign_in_as(@user)
    # Set API_URL for tests
    ENV["API_URL"] = "http://localhost:8000"
    # Clear cache before each test to ensure clean state
    Rails.cache.clear
  end

  private

  # Helper method to create and destroy a portfolio, returning the destroyed portfolio's ID
  # Useful for testing 404 responses for non-existent portfolios
  def create_and_destroy_portfolio
    temp_portfolio = Portfolio.create!(name: "Temp", tickers: [ { symbol: "AAPL", name: "Apple" } ], weights: { "AAPL" => 1.0 })
    temp_id = temp_portfolio.id
    temp_portfolio.destroy!
    temp_id
  end

  test "should get index" do
    get portfolios_url
    assert_response :success
  end

  test "should get new" do
    get new_portfolio_url
    assert_response :success
  end

  test "should create portfolio" do
    # Set API_URL for test or use a default
    api_url = ENV.fetch("API_URL", "http://localhost:8000")

    # Mock the API response using webmock
    stub_request(:post, "#{api_url}/calculate")
      .with(
        body: hash_including("tickers"),
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: {
          weights: [
            { ticker: "AAPL", weight: 0.5 },
            { ticker: "MSFT", weight: 0.5 }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Set up cache with tickers (since we removed the test environment mock data)
    get new_portfolio_url
    session_id = session[:session_id]
    cache_key = "tickers:new:#{session_id}"
    Rails.cache.write(cache_key, [ Ticker.new(symbol: "AAPL", name: "Apple"), Ticker.new(symbol: "MSFT", name: "Microsoft") ])

    assert_difference("Portfolio.count") do
      post portfolios_url, params: { portfolio: { name: @portfolio.name, tickers: @portfolio.tickers } }
    end
  end

  test "should show portfolio" do
    get portfolio_url(@portfolio)
    assert_response :success
  end

  test "should get edit" do
    get edit_portfolio_url(@portfolio)
    assert_response :success
  end

  test "should update portfolio" do
    api_url = ENV.fetch("API_URL", "http://localhost:8000")

    # Mock the API response for update
    stub_request(:post, "#{api_url}/calculate")
      .with(
        body: hash_including("tickers"),
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: {
          weights: [
            { ticker: "AAPL", weight: 0.3 },
            { ticker: "MSFT", weight: 0.7 }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Set up cache with tickers (edit action populates cache from portfolio)
    get edit_portfolio_url(@portfolio)
    session_id = session[:session_id]
    cache_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"
    # Add another ticker to the cache
    Rails.cache.write(cache_key, [
      Ticker.new(symbol: "AAPL", name: "Apple"),
      Ticker.new(symbol: "MSFT", name: "Microsoft")
    ])

    # The update method only updates tickers and weights, not the name
    # So we test that the tickers and weights are updated
    patch portfolio_url(@portfolio), params: {
      portfolio: {
        tickers: [
          { symbol: "AAPL", name: "Apple" },
          { symbol: "MSFT", name: "Microsoft" }
        ]
      }
    }

    assert_redirected_to portfolio_url(@portfolio)
    @portfolio.reload
    # Verify the tickers were updated
    assert_equal 2, @portfolio.tickers.length
    assert_equal "AAPL", @portfolio.tickers.first["symbol"]
    assert_equal "MSFT", @portfolio.tickers.last["symbol"]
  end

  test "should handle API failure gracefully" do
    # Test update when the API call fails - the controller should handle this gracefully
    api_url = ENV.fetch("API_URL", "http://localhost:8000")
    stub_request(:post, "#{api_url}/calculate")
      .to_return(status: 500, body: "Internal Server Error")

    patch portfolio_url(@portfolio), params: {
      portfolio: {
        name: "Updated Portfolio",
        tickers: []
      }
    }

    # Expect a graceful response, e.g., re-rendering the edit page with an error message
    assert_response :unprocessable_entity
    assert_select "div[style*='color: red']", /There was a problem updating the portfolio/
  end

  test "should destroy portfolio" do
    assert_difference("Portfolio.count", -1) do
      delete portfolio_url(@portfolio)
    end

    assert_redirected_to portfolios_url
  end

  test "should get edit for non-existent portfolio" do
    # Create a portfolio and then delete it to ensure it doesn't exist
    temp_id = create_and_destroy_portfolio

    # Verify the portfolio is actually deleted
    assert_raises(ActiveRecord::RecordNotFound) do
      Portfolio.find(temp_id)
    end

    # Rails will catch the exception and return a 404 response
    get edit_portfolio_url(id: temp_id)
    assert_response :not_found
  end

  test "should not update non-existent portfolio" do
    # Create a portfolio and then delete it to ensure it doesn't exist
    temp_id = create_and_destroy_portfolio

    # Rails will catch the exception and return a 404 response
    patch portfolio_url(id: temp_id), params: {
      portfolio: { name: "Updated Portfolio" }
    }
    assert_response :not_found
  end

  test "should not destroy non-existent portfolio" do
    # Create a portfolio and then delete it to ensure it doesn't exist
    temp_id = create_and_destroy_portfolio

    # Rails will catch the exception and return a 404 response
    delete portfolio_url(id: temp_id)
    assert_response :not_found
  end

  test "edit action writes tickers to portfolio-specific cache" do
    get edit_portfolio_url(@portfolio)

    session_id = session[:session_id]
    cache_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"

    # Verify cache was written with portfolio's existing tickers
    cached = Rails.cache.read(cache_key)
    assert_not_nil cached, "Cache should contain tickers after edit"
    assert_operator cached.length, :>, 0, "Cache should have tickers"
  end

  test "update action reads from portfolio-specific cache and clears it" do
    api_url = ENV.fetch("API_URL", "http://localhost:8000")

    stub_request(:post, "#{api_url}/calculate")
      .with(
        body: hash_including("tickers"),
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: {
          weights: [
            { ticker: "AAPL", weight: 0.6 },
            { ticker: "MSFT", weight: 0.4 }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # First, edit to set up the cache
    get edit_portfolio_url(@portfolio)
    session_id = session[:session_id]
    cache_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"

    # Verify cache has data
    assert_not_nil Rails.cache.read(cache_key)

    # Now update
    patch portfolio_url(@portfolio), params: {
      portfolio: {
        tickers: [
          { symbol: "AAPL", name: "Apple" },
          { symbol: "MSFT", name: "Microsoft" }
        ]
      }
    }

    assert_redirected_to portfolio_url(@portfolio)

    # Verify cache was cleared after successful update
    assert_nil Rails.cache.read(cache_key), "Cache should be cleared after update"
  end

  test "cache isolation between new and edit sessions" do
    portfolio_two = Portfolio.create!(
      name: "Second Portfolio",
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    begin
      get new_portfolio_url
      session_id = session[:session_id]

      new_cache_key = "tickers:new:#{session_id}"
      edit_cache_key = "tickers:edit:#{session_id}:portfolio_#{portfolio_two.id}"

      # Write to new cache
      Rails.cache.write(new_cache_key, [ Ticker.new(symbol: "AAPL", name: "Apple") ])

      # Edit sets up portfolio cache
      get edit_portfolio_url(portfolio_two)

      # Verify keys are different and caches are isolated
      assert_not_equal new_cache_key, edit_cache_key

      new_cached = Rails.cache.read(new_cache_key)
      edit_cached = Rails.cache.read(edit_cache_key)

      assert_not_nil new_cached, "New cache should exist"
      assert_not_nil edit_cached, "Edit cache should exist"

      # They should contain different data
      assert new_cached.any? { |t| t.symbol == "AAPL" }
      assert edit_cached.any? { |t| t.symbol == "MSFT" }
    ensure
      portfolio_two.destroy
    end
  end
end
