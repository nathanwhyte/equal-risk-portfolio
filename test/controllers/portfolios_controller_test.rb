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
end
