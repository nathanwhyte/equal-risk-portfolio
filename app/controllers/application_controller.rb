class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :assign_session_id

  private

  def assign_session_id
    session[:session_id] ||= SecureRandom.uuid
  end

  def ticker_cache_key(portfolio_id = nil)
    if portfolio_id
      "tickers:edit:#{session[:session_id]}:portfolio_#{portfolio_id}"
    else
      "tickers:new:#{session[:session_id]}"
    end
  end

  def cached_tickers(portfolio_id = nil)
    Rails.cache.read(ticker_cache_key(portfolio_id)) || []
  end

  def write_cached_tickers(tickers, portfolio_id = nil)
    Rails.logger.info "Writing #{tickers} to cache with key: #{ticker_cache_key(portfolio_id)}"
    Rails.cache.write(ticker_cache_key(portfolio_id), tickers)
  end

  def clear_cached_tickers(portfolio_id = nil)
    Rails.cache.delete(ticker_cache_key(portfolio_id))
  end
end
