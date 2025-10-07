require "application_system_test_case"

class PortfoliosTest < ApplicationSystemTestCase
  setup do
    @portfolio = portfolios(:one)
  end

  test "visiting the index" do
    visit portfolios_url
    assert_selector "h1", text: "Portfolios"
  end

  test "should create portfolio" do
    visit portfolios_url
    click_on "New portfolio"

    Rails.cache.write("tickers", @portfolio.tickers)
    click_on "Next"

    assert_text "Portfolio was successfully created"
    click_on "Back to portfolios"
  end

  test "should update Portfolio" do
    visit portfolio_url(@portfolio)
    click_on "Edit this portfolio", match: :first

    # fill_in "Name", with: @portfolio.name
    Rails.cache.write("tickers", @portfolio.tickers)
    click_on "Next"

    assert_text "Portfolio was successfully updated"
    click_on "Back to portfolios"
  end

  test "should destroy Portfolio" do
    visit portfolio_url(@portfolio)
    click_on "Destroy this portfolio", match: :first

    assert_text "Portfolio was successfully destroyed"
  end
end
