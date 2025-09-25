class CreateStockInfos < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_infos do |t|
      t.string :ticker, null: false
      t.string :name, null: false
      t.boolean :active
      t.string :sector
      t.string :logo_url, null: false

      t.timestamps
    end
  end
end
