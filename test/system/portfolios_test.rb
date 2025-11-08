require "application_system_test_case"

class PortfoliosTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_as(@user)
    @portfolio = portfolios(:one)
    @portfolio.create_initial_version
    ENV["API_URL"] = "http://localhost:8000"
  end

  test "user can view and navigate portfolio versions" do
    # Create additional versions
    @portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      title: "Added Microsoft"
    )

    @portfolio.create_new_version(
      tickers: [ { "symbol" => "GOOGL", "name" => "Google" } ],
      weights: { "GOOGL" => 1.0 },
      title: "Added Google"
    )

    # Visit portfolio show page
    visit portfolio_url(@portfolio)

    # Should see latest version by default
    assert_text "GOOGL"

    # Should see version dropdown (check for label first)
    assert_text "Version:"
    # The select element should be present
    assert_selector "select", count: 1

    # Navigate to version 1
    visit version_portfolio_url(@portfolio, version_number: 1)
    assert_text "AAPL"

    # Navigate to version 2
    visit version_portfolio_url(@portfolio, version_number: 2)
    assert_text "MSFT"
    assert_text "Added Microsoft"

    # Navigate to version 3
    visit version_portfolio_url(@portfolio, version_number: 3)
    assert_text "GOOGL"
    assert_text "Added Google"
  end

  test "user can see version history summary" do
    @portfolio.create_new_version(
      tickers: [ { "symbol" => "MSFT", "name" => "Microsoft" } ],
      weights: { "MSFT" => 1.0 },
      title: "Added Microsoft",
      notes: "Switched from AAPL to MSFT"
    )

    visit portfolio_url(@portfolio)

    # Should see version history section
    assert_text "Version History"
    assert_text "Version 1"
    assert_text "Version 2"
    assert_text "Added Microsoft"
    assert_text "Switched from AAPL to MSFT"
  end

  test "user can update current version" do
    visit edit_portfolio_url(@portfolio)

    # Note: This test would require JavaScript interaction to add/remove tickers
    # For now, we'll just verify the page loads and has the update button
    # Look for the button by value or text
    assert_selector "input[type='submit'][value='Update Current Version']", visible: :all
    assert_selector "input[type='submit'][value='Create New Version']", visible: :all
  end

  test "user sees empty state when no version history exists" do
    # Create a new portfolio without versions
    new_portfolio = Portfolio.create!(
      name: "New Portfolio",
      tickers: [ { "symbol" => "TSLA", "name" => "Tesla" } ],
      weights: { "TSLA" => 1.0 }
    )

    visit portfolio_url(new_portfolio)

    # Should see message about no version history
    assert_text "No version history yet"
  end
end
