require "test_helper"

class TickersControllerTest < ActionDispatch::IntegrationTest
  setup do
    get new_portfolio_path
  end

  test "add stores hash in cache and increments count" do
    put tickers_add_path, params: { ticker: { symbol: "AAPL", name: "Apple Inc." } }, as: :turbo_stream

    cached_tickers = Rails.cache.read("tickers:#{session[:session_id]}")
    assert cached_tickers.is_a?(Array), "cached tickers should be an array"
    assert_equal 1, cached_tickers.length
    entry = cached_tickers.first
    assert entry.is_a?(Hash), "cache entry should be a Hash"
    assert_equal "AAPL", entry["symbol"]
    assert_equal "Apple Inc.", entry["name"]
  end

  test "add does not duplicate same symbol" do
    # Seed cache with existing ticker hash (simulating cache round-trip)
    put tickers_add_path, params: { ticker: { symbol: "AAPL", name: "Apple Inc." } }, as: :turbo_stream
    cached_tickers = Rails.cache.read("tickers:#{session[:session_id]}")
    assert_equal 1, cached_tickers.length

    # Add same symbol again
    put tickers_add_path, params: { ticker: { symbol: "AAPL", name: "Apple Inc." } }, as: :turbo_stream
    assert_response :success
    cached_tickers = Rails.cache.read("tickers:#{session[:session_id]}")
    assert_equal 1, cached_tickers.length, "should not duplicate ticker by symbol"
  end
end
