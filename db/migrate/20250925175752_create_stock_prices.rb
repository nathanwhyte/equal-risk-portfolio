class CreateStockPrices < ActiveRecord::Migration[8.0]
  def change
    create_table(:stock_prices) do |t|
      t.date(:trade_date, null: false)
      t.string(:ticker, null: false)
      t.decimal(:close_price, null: false)

      t.timestamps
    end
  end
end
