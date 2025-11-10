class CreatePortfolioVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolio_versions do |t|
      t.references :portfolio, null: false, foreign_key: true, type: :uuid

      t.jsonb :tickers, null: false
      t.jsonb :weights, null: false

      t.string :title
      t.string :notes

      t.integer :version_number, null: false
      t.datetime :created_at, null: false

      # Indexes
      t.index [ :portfolio_id, :version_number ], unique: true, name: "index_portfolio_versions_on_portfolio_and_version"
    end
  end
end
