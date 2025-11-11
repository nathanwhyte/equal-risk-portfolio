require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "current_tickers returns tickers from portfolio" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { "symbol" => "AAPL", "name" => "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    assert_equal portfolio.tickers, portfolio.current_tickers
  end

  test "current_tickers returns empty array when tickers is nil" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: nil,
      weights: {}
    )

    assert_equal [], portfolio.current_tickers
  end

  test "current_weights returns weights from portfolio" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { "symbol" => "AAPL", "name" => "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    assert_equal portfolio.weights, portfolio.current_weights
  end

  test "current_weights returns empty hash when weights is nil" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [],
      weights: nil
    )

    assert_equal({}, portfolio.current_weights)
  end
end
