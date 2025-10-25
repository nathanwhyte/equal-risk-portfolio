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

  test "should show delete confirmation dialog when clicking destroy button" do
    visit portfolio_url(@portfolio)

    # Click the destroy button
    click_button "Destroy"

    # Check that the confirmation dialog is shown
    dialog = page.driver.browser.switch_to.alert
    assert_equal "Are you sure you want to destroy this portfolio?", dialog.text

    # Cancel the dialog
    dialog.dismiss
  end

  test "should delete portfolio when confirming the delete dialog" do
    # Create a temporary portfolio for deletion
    temp_portfolio = Portfolio.create!(
      name: "Temp Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    visit portfolio_url(temp_portfolio)

    # Click the destroy button and confirm
    assert_difference("Portfolio.count", -1) do
      accept_confirm "Are you sure you want to destroy this portfolio?" do
        click_button "Destroy"
      end

      # Should be redirected to portfolios index
      assert_current_path portfolios_path
    end

    # Verify the portfolio is deleted
    assert_raises(ActiveRecord::RecordNotFound) do
      Portfolio.find(temp_portfolio.id)
    end
  end

  test "should not delete portfolio when cancelling the delete dialog" do
    # Create a temporary portfolio for testing
    temp_portfolio = Portfolio.create!(
      name: "Temp Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    visit portfolio_url(temp_portfolio)

    # Click the destroy button and dismiss
    assert_no_difference("Portfolio.count") do
      dismiss_confirm "Are you sure you want to destroy this portfolio?" do
        click_button "Destroy"
      end

      # Should still be on the portfolio show page
      assert_current_path portfolio_path(temp_portfolio)
    end

    # Clean up
    temp_portfolio.destroy
  end
end
