class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :assign_session_id

  private

  def assign_session_id
    session[:session_id] ||= SecureRandom.uuid
  end

  def ticker_cache_key(mode:, portfolio_id: nil, original_portfolio_id: nil)
    case mode
    when :edit
      "tickers:edit:#{session[:session_id]}:portfolio_#{portfolio_id}"
    when :new_copy
      if original_portfolio_id
        "tickers:new_copy:#{session[:session_id]}:from_portfolio_#{original_portfolio_id}"
      else
        "tickers:new_copy:#{session[:session_id]}"
      end
    when :new
      "tickers:new:#{session[:session_id]}"
    else
      raise ArgumentError, "Invalid mode: #{mode}. Must be :new, :new_copy, or :edit"
    end
  end

  def cached_tickers(mode:, portfolio_id: nil, original_portfolio_id: nil)
    Rails.cache.read(ticker_cache_key(mode: mode, portfolio_id: portfolio_id, original_portfolio_id: original_portfolio_id)) || []
  end

  def write_cached_tickers(tickers, mode:, portfolio_id: nil, original_portfolio_id: nil)
    cache_key = ticker_cache_key(mode: mode, portfolio_id: portfolio_id, original_portfolio_id: original_portfolio_id)
    Rails.logger.info "Writing #{tickers} to cache with key: #{cache_key}"
    Rails.cache.write(cache_key, tickers)
  end

  def clear_cached_tickers(mode:, portfolio_id: nil, original_portfolio_id: nil)
    Rails.cache.delete(ticker_cache_key(mode: mode, portfolio_id: portfolio_id, original_portfolio_id: original_portfolio_id))
  end
end
