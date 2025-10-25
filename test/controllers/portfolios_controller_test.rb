require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @portfolio = portfolios(:one)
    # Set API_URL for tests
    ENV["API_URL"] = "http://localhost:8000"
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
    assert_response :success
    assert_select ".alert", /There was a problem updating the portfolio/
  end

  test "should destroy portfolio" do
    assert_difference("Portfolio.count", -1) do
      delete portfolio_url(@portfolio)
    end

    assert_redirected_to portfolios_url
  end

  test "should get edit for non-existent portfolio" do
    # Create a portfolio and then delete it to ensure it doesn't exist
    temp_portfolio = Portfolio.create!(name: "Temp", tickers: [ { symbol: "AAPL", name: "Apple" } ], weights: { "AAPL" => 1.0 })
    temp_id = temp_portfolio.id
    temp_portfolio.destroy!

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
    temp_portfolio = Portfolio.create!(name: "Temp", tickers: [ { symbol: "AAPL", name: "Apple" } ], weights: { "AAPL" => 1.0 })
    temp_id = temp_portfolio.id
    temp_portfolio.destroy!

    # Rails will catch the exception and return a 404 response
    patch portfolio_url(id: temp_id), params: {
      portfolio: { name: "Updated Portfolio" }
    }
    assert_response :not_found
  end

  test "should not destroy non-existent portfolio" do
    # Create a portfolio and then delete it to ensure it doesn't exist
    temp_portfolio = Portfolio.create!(name: "Temp", tickers: [ { symbol: "AAPL", name: "Apple" } ], weights: { "AAPL" => 1.0 })
    temp_id = temp_portfolio.id
    temp_portfolio.destroy!

    # Rails will catch the exception and return a 404 response
    delete portfolio_url(id: temp_id)
    assert_response :not_found
  end
end
