class CreatePortfolios < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pgcrypto"

    create_table :portfolios, id: false do |t|
      t.string :id, primary_key: true, default: "uuid_generate_v4()"
      t.string :name, default: "New Portfolio"
      t.text :tickers, array: true, default: []

      t.timestamps
    end
  end
end
