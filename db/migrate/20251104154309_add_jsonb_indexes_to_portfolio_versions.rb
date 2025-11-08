class AddJsonbIndexesToPortfolioVersions < ActiveRecord::Migration[8.1]
  def change
    # GIN indexes for efficient jsonb queries
    add_index :portfolio_versions, :tickers, using: :gin, name: "index_portfolio_versions_on_tickers_gin"
    add_index :portfolio_versions, :weights, using: :gin, name: "index_portfolio_versions_on_weights_gin"
  end
end
