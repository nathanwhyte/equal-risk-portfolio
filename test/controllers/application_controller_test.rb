require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # Disable parallel execution for these tests since they rely on shared cache state
  parallelize(workers: 1)

  setup do
    @portfolio = portfolios(:one)
    # Clear cache before each test to ensure clean state
    Rails.cache.clear
  end

  test "ticker_cache_key generates correct key for new portfolio" do
    # Establish a session to get a session_id
    get new_portfolio_url
    controller = @controller
    session_id = session[:session_id]

    expected_key = "tickers:new:#{session_id}"
    actual_key = controller.send(:ticker_cache_key, nil)

    assert_equal expected_key, actual_key
    assert_match(/^tickers:new:.+$/, actual_key)
  end

  test "ticker_cache_key generates correct key for editing portfolio" do
    # Establish a session to get a session_id
    get edit_portfolio_url(@portfolio)
    controller = @controller
    session_id = session[:session_id]
    portfolio_id = @portfolio.id

    expected_key = "tickers:edit:#{session_id}:portfolio_#{portfolio_id}"
    actual_key = controller.send(:ticker_cache_key, portfolio_id)

    assert_equal expected_key, actual_key
    assert_match(/^tickers:edit:.+:portfolio_.+$/, actual_key)
  end

  test "different portfolios use isolated cache keys" do
    portfolio_two = Portfolio.create!(
      name: "Second Portfolio",
      tickers: [ { symbol: "MSFT", name: "Microsoft" } ],
      weights: { "MSFT" => 1.0 }
    )

    begin
      get new_portfolio_url
      session_id = session[:session_id]

      new_cache_key = "tickers:new:#{session_id}"
      edit_key_one = "tickers:edit:#{session_id}:portfolio_#{@portfolio.id}"
      edit_key_two = "tickers:edit:#{session_id}:portfolio_#{portfolio_two.id}"

      # Verify all keys are unique
      assert_not_equal new_cache_key, edit_key_one
      assert_not_equal new_cache_key, edit_key_two
      assert_not_equal edit_key_one, edit_key_two

      # Verify keys contain expected identifiers
      assert_includes edit_key_one, @portfolio.id.to_s
      assert_includes edit_key_two, portfolio_two.id.to_s
    ensure
      portfolio_two.destroy
    end
  end

  test "write and read cached tickers for new portfolio" do
    get new_portfolio_url
    controller = @controller

    tickers = [ Ticker.new(symbol: "AAPL", name: "Apple"), Ticker.new(symbol: "GOOGL", name: "Google") ]
    controller.send(:write_cached_tickers, tickers, nil)

    cached = controller.send(:cached_tickers, nil)
    assert_equal 2, cached.length
    assert_equal "AAPL", cached[0].symbol
    assert_equal "GOOGL", cached[1].symbol
  end

  test "write and read cached tickers for edited portfolio" do
    get edit_portfolio_url(@portfolio)
    controller = @controller

    tickers = [ Ticker.new(symbol: "MSFT", name: "Microsoft") ]
    controller.send(:write_cached_tickers, tickers, @portfolio.id)

    cached = controller.send(:cached_tickers, @portfolio.id)
    assert_equal 1, cached.length
    assert_equal "MSFT", cached[0].symbol
  end

  test "cached tickers are isolated between different portfolios" do
    portfolio_two = Portfolio.create!(
      name: "Second Portfolio",
      tickers: [ { symbol: "TSLA", name: "Tesla" } ],
      weights: { "TSLA" => 1.0 }
    )

    begin
      get new_portfolio_url
      controller = @controller

      # Write different tickers to each portfolio cache
      tickers_one = [ Ticker.new(symbol: "AAPL", name: "Apple") ]
      tickers_two = [ Ticker.new(symbol: "GOOGL", name: "Google") ]

      controller.send(:write_cached_tickers, tickers_one, @portfolio.id)
      controller.send(:write_cached_tickers, tickers_two, portfolio_two.id)

      # Verify isolation - each portfolio has its own cached data
      cached_one = controller.send(:cached_tickers, @portfolio.id)
      cached_two = controller.send(:cached_tickers, portfolio_two.id)

      assert_equal 1, cached_one.length
      assert_equal "AAPL", cached_one[0].symbol

      assert_equal 1, cached_two.length
      assert_equal "GOOGL", cached_two[0].symbol
    ensure
      portfolio_two.destroy
    end
  end

  test "clear_cached_tickers removes correct cache" do
    get new_portfolio_url
    controller = @controller

    # Write to new cache
    tickers = [ Ticker.new(symbol: "AAPL", name: "Apple") ]
    controller.send(:write_cached_tickers, tickers, nil)

    # Verify it's there
    assert_equal 1, controller.send(:cached_tickers, nil).length

    # Clear it
    controller.send(:clear_cached_tickers, nil)

    # Verify it's gone
    assert_equal 0, controller.send(:cached_tickers, nil).length
  end

  test "clearing one portfolio cache does not affect another" do
    portfolio_two = Portfolio.create!(
      name: "Second Portfolio",
      tickers: [ { symbol: "TSLA", name: "Tesla" } ],
      weights: { "TSLA" => 1.0 }
    )

    begin
      get new_portfolio_url
      controller = @controller

      # Write to both caches
      tickers_one = [ Ticker.new(symbol: "AAPL", name: "Apple") ]
      tickers_two = [ Ticker.new(symbol: "GOOGL", name: "Google") ]

      controller.send(:write_cached_tickers, tickers_one, @portfolio.id)
      controller.send(:write_cached_tickers, tickers_two, portfolio_two.id)

      # Clear only portfolio one's cache
      controller.send(:clear_cached_tickers, @portfolio.id)

      # Verify portfolio one's cache is cleared
      assert_equal 0, controller.send(:cached_tickers, @portfolio.id).length

      # Verify portfolio two's cache is intact
      cached_two = controller.send(:cached_tickers, portfolio_two.id)
      assert_equal 1, cached_two.length
      assert_equal "GOOGL", cached_two[0].symbol
    ensure
      portfolio_two.destroy
    end
  end
end
