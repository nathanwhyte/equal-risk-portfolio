require "application_system_test_case"

class PortfoliosTest < ApplicationSystemTestCase
  setup do
    @portfolio = portfolios(:one)
  end

  test "visiting the index" do
    visit portfolios_url
    assert_selector "h1", text: "Portfolios"
  end

  test "should visit new portfolio page" do
    visit portfolios_url
    click_on "Create a Portfolio"

    # Assert we're on the new portfolio page
    assert_selector "h1", text: "Create a Portfolio"
  end
end
