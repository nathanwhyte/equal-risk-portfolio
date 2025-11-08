require "test_helper"

class PortfolioVersionTest < ActiveSupport::TestCase
  setup do
    @portfolio = portfolios(:one)
  end

  test "belongs to portfolio" do
    version = PortfolioVersion.new(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 },
      version_number: 1
    )

    assert version.valid?
    assert_equal @portfolio, version.portfolio
  end

  test "requires tickers and weights" do
    version = PortfolioVersion.new(portfolio: @portfolio, version_number: 1)
    assert_not version.valid?
    assert_includes version.errors[:tickers], "can't be blank"
    assert_includes version.errors[:weights], "can't be blank"
  end

  test "version_number must be unique per portfolio" do
    PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 },
      version_number: 1
    )

    duplicate = PortfolioVersion.new(
      portfolio: @portfolio,
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      version_number: 1
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:version_number], "has already been taken"
  end

  test "version_number can be same for different portfolios" do
    portfolio_two = portfolios(:two)
    PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 },
      version_number: 1
    )

    version_for_other_portfolio = PortfolioVersion.new(
      portfolio: portfolio_two,
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      version_number: 1
    )

    assert version_for_other_portfolio.valid?
  end

  test "ticker_symbols returns array of symbols" do
    version = PortfolioVersion.new(
      portfolio: @portfolio,
      tickers: [
        { symbol: "AAPL", name: "Apple" },
        { symbol: "MSFT", name: "Microsoft" }
      ],
      weights: { "AAPL" => 0.5, "MSFT" => 0.5 },
      version_number: 1
    )

    assert_equal [ "AAPL", "MSFT" ], version.ticker_symbols
  end

  test "ticker_symbols handles string keys" do
    version = PortfolioVersion.new(
      portfolio: @portfolio,
      tickers: [
        { "symbol" => "AAPL", "name" => "Apple" }
      ],
      weights: { "AAPL" => 1.0 },
      version_number: 1
    )

    assert_equal [ "AAPL" ], version.ticker_symbols
  end

  test "weight_for returns weight for ticker" do
    version = PortfolioVersion.new(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 0.75 },
      version_number: 1
    )

    assert_equal 0.75, version.weight_for("AAPL")
    assert_nil version.weight_for("MSFT")
  end

  test "weight_for handles symbol keys" do
    version = PortfolioVersion.new(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 0.5 },
      version_number: 1
    )

    assert_equal 0.5, version.weight_for(:AAPL)
  end

  test "by_version scope filters by version number" do
    version1 = PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 },
      version_number: 1
    )
    version2 = PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      version_number: 2
    )

    found = PortfolioVersion.by_version(1)
    assert_equal 1, found.count
    assert_equal version1.id, found.first.id
  end

  test "chronological scope orders by version number descending" do
    version1 = PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 },
      version_number: 1,
      created_at: 2.days.ago
    )
    version2 = PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      version_number: 2,
      created_at: 1.day.ago
    )

    chronological = PortfolioVersion.where(portfolio: @portfolio).chronological
    assert_equal [ version2.id, version1.id ], chronological.map(&:id)
  end

  test "recent scope orders by created_at descending" do
    version1 = PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 },
      version_number: 1,
      created_at: 2.days.ago
    )
    version2 = PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      version_number: 2,
      created_at: 1.day.ago
    )

    recent = PortfolioVersion.where(portfolio: @portfolio).recent
    assert_equal [ version2.id, version1.id ], recent.map(&:id)
  end

  test "latest scope returns most recent version" do
    PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 },
      version_number: 1,
      created_at: 2.days.ago
    )
    latest = PortfolioVersion.create!(
      portfolio: @portfolio,
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      version_number: 2,
      created_at: 1.day.ago
    )

    found = PortfolioVersion.where(portfolio: @portfolio).order(created_at: :desc).first
    assert_equal latest.id, found.id
  end
end
