class DropPortfolioVersions < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :portfolio_versions, :portfolios
    drop_table :portfolio_versions
  end
end
