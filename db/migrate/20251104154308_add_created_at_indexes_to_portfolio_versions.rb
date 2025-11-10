class AddCreatedAtIndexesToPortfolioVersions < ActiveRecord::Migration[8.1]
  def change
    add_index :portfolio_versions, :created_at, name: "index_portfolio_versions_on_created_at"
    add_index :portfolio_versions, [ :portfolio_id, :created_at ], name: "index_portfolio_versions_on_portfolio_and_created_at"
  end
end
