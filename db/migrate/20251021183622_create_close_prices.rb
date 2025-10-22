class CreateClosePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :close_prices, id: :uuid do |t|
      t.string :ticker
      t.string :date
      t.float :close

      t.timestamps
    end

    add_index :close_prices, :ticker
  end
end
