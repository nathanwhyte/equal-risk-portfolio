require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "create_initial_version creates version 1 when portfolio is created" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { "symbol" => "AAPL", "name" => "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    portfolio.create_initial_version

    assert_equal 1, portfolio.portfolio_versions.count
    version = portfolio.portfolio_versions.first
    assert_equal 1, version.version_number
    assert_equal "Create \"Test Portfolio\"", version.title
    assert_equal "", version.notes
  end

  test "create_new_version stores new state and increments version number" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    new_tickers = [ { "symbol" => "MSFT", "name" => "Microsoft" } ]
    new_weights = { "MSFT" => 1.0 }

    portfolio.create_new_version(
      tickers: new_tickers,
      weights: new_weights,
      title: "Add Microsoft",
      notes: "Switched to MSFT"
    )

    assert_equal 2, portfolio.portfolio_versions.count
    latest = portfolio.latest_version
    assert_equal 2, latest.version_number
    assert_equal "Add Microsoft", latest.title
    assert_equal "Switched to MSFT", latest.notes
    assert_equal new_tickers, latest.tickers
    assert_equal new_weights, latest.weights
  end

  test "create_new_version stores allocations in snapshot" do
    portfolio = portfolios(:one)
    allocations = { "Bonds" => { "weight" => 20.0, "enabled" => true } }
    portfolio.update!(allocations: allocations)
    portfolio.create_initial_version

    new_tickers = [ { "symbol" => "MSFT", "name" => "Microsoft" } ]
    new_weights = { "MSFT" => 1.0 }

    portfolio.create_new_version(
      tickers: new_tickers,
      weights: new_weights,
      title: "Add Microsoft"
    )

    latest = portfolio.latest_version
    assert_equal allocations, latest.allocations
  end

  test "create_new_version accepts nil title and notes" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      title: nil,
      notes: nil
    )

    latest = portfolio.latest_version
    assert_nil latest.title
    assert_nil latest.notes
  end

  test "update_latest_version updates existing version without creating new one" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    new_tickers = [ { "symbol" => "MSFT", "name" => "Microsoft" } ]
    new_weights = { "MSFT" => 1.0 }

    portfolio.update_latest_version(tickers: new_tickers, weights: new_weights)

    assert_equal 1, portfolio.portfolio_versions.count
    latest = portfolio.latest_version
    assert_equal new_tickers, latest.tickers
    assert_equal new_weights, latest.weights
  end

  test "update_latest_version creates initial version if none exists" do
    portfolio = portfolios(:one)
    assert_equal 0, portfolio.portfolio_versions.count

    new_tickers = [ { "symbol" => "MSFT", "name" => "Microsoft" } ]
    new_weights = { "MSFT" => 1.0 }

    portfolio.update_latest_version(tickers: new_tickers, weights: new_weights)

    assert_equal 1, portfolio.portfolio_versions.count
    latest = portfolio.latest_version
    assert_equal 1, latest.version_number
  end

  test "update_latest_version stores current allocations" do
    portfolio = portfolios(:one)
    allocations = { "Bonds" => { "weight" => 20.0, "enabled" => true } }
    portfolio.update!(allocations: allocations)
    portfolio.create_initial_version

    portfolio.update_latest_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    latest = portfolio.latest_version
    assert_equal allocations, latest.allocations
  end

  test "versions are not created automatically on update" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version
    original_version_count = portfolio.portfolio_versions.count

    # Regular update does not create a version (only when explicitly requested)
    portfolio.update!(tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ])

    assert_equal original_version_count, portfolio.portfolio_versions.count
  end

  test "allocations are not versioned but stored in version snapshots" do
    portfolio = portfolios(:one)
    allocations = { "Bonds" => { "weight" => 20.0, "enabled" => true } }
    portfolio.update!(allocations: allocations)
    portfolio.create_initial_version

    # Allocations are included in version snapshot
    version = portfolio.latest_version
    assert_equal allocations, version.allocations

    # But changing allocations does not create a new version
    portfolio.update!(allocations: { "Bonds" => { "weight" => 30.0, "enabled" => true } })
    assert_equal 1, portfolio.portfolio_versions.count
  end

  test "name changes do not create versions" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version
    original_version_count = portfolio.portfolio_versions.count

    portfolio.update!(name: "New Name")

    assert_equal original_version_count, portfolio.portfolio_versions.count
  end

  test "latest_version returns most recent version" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )
    portfolio.create_new_version(
      tickers: [ { "symbol" => "GOOGL", "name" => "Google" } ],
      weights: { "GOOGL" => 1.0 }
    )

    latest = portfolio.latest_version
    assert_equal 3, latest.version_number
    # Latest version should have the newest state (GOOGL)
    assert_equal "GOOGL", latest.ticker_symbols.first
  end

  test "latest_version returns nil when no versions exist" do
    portfolio = portfolios(:one)
    assert_nil portfolio.latest_version
  end

  test "version_at returns version by number" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    version1 = portfolio.version_at(1)
    version2 = portfolio.version_at(2)

    assert_equal 1, version1.version_number
    assert_equal 2, version2.version_number
  end

  test "version_at returns nil for non-existent version" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    assert_nil portfolio.version_at(999)
  end

  test "version numbers are sequential per portfolio" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )
    portfolio.create_new_version(
      tickers: [ { "symbol" => "GOOGL", "name" => "Google" } ],
      weights: { "GOOGL" => 1.0 }
    )
    portfolio.create_new_version(
      tickers: [ { "symbol" => "TSLA", "name" => "Tesla" } ],
      weights: { "TSLA" => 1.0 }
    )

    versions = portfolio.portfolio_versions.order(version_number: :asc)
    assert_equal 4, versions.count
    assert_equal [ 1, 2, 3, 4 ], versions.map(&:version_number)
  end

  test "current_tickers returns tickers from latest version" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    new_tickers = [ { "symbol" => "MSFT", "name" => "Microsoft" } ]
    portfolio.create_new_version(
      tickers: new_tickers,
      weights: { "MSFT" => 1.0 }
    )

    assert_equal new_tickers, portfolio.current_tickers
  end

  test "current_tickers falls back to stored portfolio data" do
    portfolio = portfolios(:one)
    # No versions created

    assert_equal portfolio.tickers, portfolio.current_tickers
  end

  test "current_weights returns weights from latest version" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    new_weights = { "MSFT" => 1.0 }
    portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: new_weights
    )

    assert_equal new_weights, portfolio.current_weights
  end

  test "current_weights falls back to stored portfolio data" do
    portfolio = portfolios(:one)
    # No versions created

    assert_equal portfolio.weights, portfolio.current_weights
  end

  test "create_version_with_current_state creates version from current state" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version

    # Update portfolio table (but not the latest version)
    portfolio.update!(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    # Create version from current state
    # Note: current_tickers reads from latest_version (which still has AAPL), not from portfolio table
    portfolio.create_version_with_current_state(title: "Before change", notes: "Saved state")

    versions = portfolio.portfolio_versions.order(version_number: :asc)
    assert_equal 2, versions.count

    # The version should capture the state from latest_version (AAPL), not the portfolio table (MSFT)
    # This is the expected behavior - current_tickers prioritizes latest_version over portfolio table
    version2 = versions.last
    assert_equal [ { "symbol" => "AAPL", "name" => "Apple" } ], version2.tickers
  end

  test "create_new_version does not create version for non-persisted portfolio" do
    portfolio = Portfolio.new(
      name: "Test",
      tickers: [ { "symbol" => "AAPL", "name" => "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    assert_no_difference "PortfolioVersion.count" do
      portfolio.create_new_version(
        tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
        weights: { "MSFT" => 1.0 }
      )
    end
  end

  test "portfolio versions are destroyed when portfolio is destroyed" do
    portfolio = portfolios(:one)
    portfolio.create_initial_version
    portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    assert_equal 2, portfolio.portfolio_versions.count

    portfolio.destroy

    assert_equal 0, PortfolioVersion.where(portfolio_id: portfolio.id).count
  end
end
