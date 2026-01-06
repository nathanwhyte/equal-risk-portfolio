# frozen_string_literal: true

class AddUniqueIndexToClosePricesOnTickerAndDate < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicates, keeping one row for each (ticker, date) pair
    execute <<-SQL
      DELETE FROM close_prices
      WHERE ctid NOT IN (
        SELECT MIN(ctid)
        FROM close_prices
        GROUP BY ticker, date
      )
    SQL

    # Add unique index on (ticker, date)
    add_index :close_prices, [ :ticker, :date ], unique: true
  end

  def down
    remove_index :close_prices, [ :ticker, :date ]
  end
end
