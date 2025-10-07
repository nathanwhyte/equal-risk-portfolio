class CreatePortfolios < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolios do |t|
      t.string :name, default: "New Portfolio"
      t.text :tickers, array: true, default: []

      t.timestamps
    end
  end
end
