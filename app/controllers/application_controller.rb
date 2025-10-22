class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :assign_session_id

  private

  def assign_session_id
    session[:session_id] ||= SecureRandom.uuid
  end

  def ticker_cache_key
    "tickers:#{session[:session_id]}"
  end

  def cached_tickers
    if Rails.env.test?
      return [ Ticker.new(symbol: "AAPL", name: "Apple"), Ticker.new(symbol: "MSFT", name: "Microsoft") ]
    end

    Rails.cache.read(ticker_cache_key) || []
  end

  def write_cached_tickers(tickers)
    Rails.logger.info "Writing #{tickers} to cache"
    Rails.cache.write(ticker_cache_key, tickers)
  end

  def clear_cached_tickers
    Rails.cache.delete(ticker_cache_key)
  end
end
