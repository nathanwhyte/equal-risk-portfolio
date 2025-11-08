module PortfolioVersions
  extend ActiveSupport::Concern

  private

  def load_portfolio_version(portfolio, version_number)
    portfolio.portfolio_versions.by_version(version_number).first
  end

  def load_latest_version_data(portfolio)
    latest = portfolio.latest_version
    if latest
      tickers, weights = version_tickers_and_weights(latest)
      [ tickers, weights, latest ]
    else
      [ portfolio.tickers || [], portfolio.weights || {}, nil ]
    end
  end

  def version_tickers_and_weights(version)
    [ version.tickers, version.weights ]
  end
end
