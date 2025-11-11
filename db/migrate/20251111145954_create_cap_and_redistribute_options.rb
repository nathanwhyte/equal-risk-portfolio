class CreateCapAndRedistributeOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :cap_and_redistribute_options, if_not_exists: true do |t|
      t.references :portfolio, null: false, foreign_key: true, type: :uuid

      t.float :cap_percentage, null: false
      t.integer :top_n, null: false
      t.boolean :active, null: false, default: false

      t.timestamps
    end
  end
end
