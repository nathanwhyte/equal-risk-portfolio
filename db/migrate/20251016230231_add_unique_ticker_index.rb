class AddUniqueTickerIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :close_prices, :ticker, unique: true
  end
end
