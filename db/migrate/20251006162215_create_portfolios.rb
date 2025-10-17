class CreatePortfolios < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pgcrypto"

    create_table :portfolios, id: :uuid do |t|
      # t.string :id, primary_key: true
      t.string :name, default: "New Portfolio"
      t.jsonb :tickers, default: {}

      t.timestamps
    end
  end
end
