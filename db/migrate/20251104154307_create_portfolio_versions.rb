class CreatePortfolioVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolio_versions do |t|
      t.references :portfolio, null: false, foreign_key: true, type: :uuid

      # Snapshot of ticker->weight->allocations mapping at this version
      t.jsonb :tickers, null: false
      t.jsonb :weights, null: false
      t.jsonb :allocations # Can be null (portfolios may not have allocations)

      # Optional metadata
      t.string :notes # Optional notes about this version

      # Version tracking
      t.integer :version_number, null: false # Sequential version number per portfolio
      t.datetime :created_at, null: false

      # Indexes
      t.index [ :portfolio_id, :version_number ], unique: true, name: "index_portfolio_versions_on_portfolio_and_version"
      t.index [ :portfolio_id, :created_at ], name: "index_portfolio_versions_on_portfolio_and_created_at"
      t.index :created_at # For global version queries
    end
  end
end
