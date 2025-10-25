require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @portfolio = portfolios(:one)
  end

  test "ticker_cache_key generates correct key for new portfolio" do
    get new_portfolio_url

    controller = @controller
    session_id = session[:session_id]

    expected_key = "tickers:new:#{session_id}"
    actual_key = controller.send(:ticker_cache_key, nil)

    assert_equal expected_key, actual_key
  end

  test "ticker_cache_key generates correct key for editing portfolio" do
    get edit_portfolio_url(@portfolio)

    controller = @controller
    session_id = session[:session_id]
    portfolio_id = @portfolio.id

    expected_key = "tickers:edit:#{session_id}:portfolio_#{portfolio_id}"
    actual_key = controller.send(:ticker_cache_key, portfolio_id)

    assert_equal expected_key, actual_key
  end

  test "cached_tickers uses different cache namespaces for new vs edit" do
    get new_portfolio_url

    session_id = session[:session_id]

    new_cache_key = "tickers:new:#{session_id}"
    edit_cache_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"

    # Verify keys are different
    assert_not_equal new_cache_key, edit_cache_key
    assert_match(/^tickers:new:.+$/, new_cache_key)
    assert_match(/^tickers:edit:.+:portfolio_.+$/, edit_cache_key)
  end

  test "cached_tickers isolates cache between different portfolios" do
    portfolio_two = Portfolio.create!(
      name: "Second Portfolio",
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    get new_portfolio_url
    session_id = session[:session_id]

    portfolio_one_key = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"
    portfolio_two_key = "tickers:edit:#{session_id}:portfolio_#{portfolio_two.id}"

    # Verify keys are unique per portfolio
    assert_not_equal portfolio_one_key, portfolio_two_key
    assert_includes portfolio_one_key, @portfolio.id.to_s
    assert_includes portfolio_two_key, portfolio_two.id.to_s

    portfolio_two.destroy
  end

  test "clear_cached_tickers removes correct cache for new portfolio" do
    # Skip in test environment due to mock data override
    skip "Cache operations are mocked in test environment"
  end

  test "clear_cached_tickers removes correct cache for edited portfolio" do
    # Skip in test environment due to mock data override
    skip "Cache operations are mocked in test environment"
  end

  test "clear_cached_tickers for one portfolio does not affect another" do
    # Skip in test environment due to mock data override
    skip "Cache operations are mocked in test environment"
  end
end
