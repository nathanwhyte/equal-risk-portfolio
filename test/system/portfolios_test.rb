require "application_system_test_case"

class PortfoliosTest < ApplicationSystemTestCase
  setup do
    @portfolio = portfolios(:one)
    @user = users(:one)
  end

  test "user can view portfolios when authenticated" do
    login_as_user
    visit portfolios_url
    assert_selector "h1", text: "Portfolios"
  end

  test "user can navigate to create portfolio page" do
    login_as_user
    visit portfolios_url
    click_on "Create a Portfolio"
    assert_selector "h1", text: "Create a Portfolio"
  end

  test "user can delete a portfolio with confirmation" do
    login_as_user

    # Create a temporary portfolio for deletion
    temp_portfolio = Portfolio.create!(
      name: "Temp Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    visit portfolio_url(temp_portfolio)

    # Delete with confirmation
    assert_difference("Portfolio.count", -1) do
      accept_confirm "Are you sure you want to destroy this portfolio?" do
        click_button "Destroy"
      end
      assert_current_path portfolios_path
    end
  end

  test "user can cancel portfolio deletion" do
    login_as_user

    temp_portfolio = Portfolio.create!(
      name: "Temp Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    visit portfolio_url(temp_portfolio)

    # Cancel deletion
    assert_no_difference("Portfolio.count") do
      dismiss_confirm "Are you sure you want to destroy this portfolio?" do
        click_button "Destroy"
      end
      assert_current_path portfolio_path(temp_portfolio)
    end

    temp_portfolio.destroy
  end

  private

  def login_as_user
    visit new_session_path
    fill_in "email_address", with: @user.email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    # Wait for redirect after login - use has_current_path? to wait for the path change
    assert has_current_path?(root_path, wait: 5), "Expected to be redirected to root path after login"
  end
end
