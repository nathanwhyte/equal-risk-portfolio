class CreateClosePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :close_prices, id: :uuid do |t|
      t.string :ticker, null: false
      t.string :date, null: false
      t.float :close, null: false

      t.timestamps
    end
  end
end
