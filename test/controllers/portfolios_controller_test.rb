require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @portfolio = portfolios(:one)
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
    assert_difference("Portfolio.count") do
      post portfolios_url, params: { portfolio: { name: @portfolio.name, tickers: @portfolio.tickers } }
    end
  end

  test "should show portfolio" do
    get portfolio_url(@portfolio)
    assert_response :success
  end
end
