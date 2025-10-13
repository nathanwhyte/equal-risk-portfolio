require "test_helper"

class TickersControllerTest < ActionDispatch::IntegrationTest
  setup do
    get new_portfolio_path
  end

  test "add stores hash in session and increments count" do
    put tickers_add_path, params: { ticker: { symbol: "AAPL", name: "Apple Inc." } }, as: :turbo_stream

    assert session[:tickers].is_a?(Array), "session[:tickers] should be an array"
    assert_equal 1, session[:tickers].length
    entry = session[:tickers].first
    assert entry.is_a?(Hash), "session entry should be a Hash"
    assert_equal "AAPL", entry["symbol"]
    assert_equal "Apple Inc.", entry["name"]
  end

  test "add does not duplicate same symbol" do
    # Seed session with existing ticker hash (simulating cookie round-trip)
    put tickers_add_path, params: { ticker: { symbol: "AAPL", name: "Apple Inc." } }, as: :turbo_stream
    assert_equal 1, session[:tickers].length

    # Add same symbol again
    put tickers_add_path, params: { ticker: { symbol: "AAPL", name: "Apple Inc." } }, as: :turbo_stream
    assert_response :success
    assert_equal 1, session[:tickers].length, "should not duplicate ticker by symbol"
  end
end
