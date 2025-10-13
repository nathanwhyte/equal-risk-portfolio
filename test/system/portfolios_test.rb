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

    session[:tickers] = @portfolio.tickers

    click_on "Next"
  end
end
