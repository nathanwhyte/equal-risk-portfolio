class CreateClosePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :close_prices, id: false do |t|
      t.string :id, primary_key: true, default: "uuid_generate_v4()"
      t.string :ticker, null: false
      t.string :date, null: false
      t.float :price, null: false

      t.timestamps
    end
  end
end
