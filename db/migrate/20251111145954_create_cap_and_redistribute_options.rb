class CreateCapAndRedistributeOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :cap_and_redistribute_options, if_not_exists: true do |t|
      t.references :portfolio, null: false, foreign_key: true, type: :uuid

      t.float :cap_percentage, null: false
      t.integer :top_n, null: false
      t.boolean :active, null: false, default: false
      t.jsonb :weights, null: false, default: {}

      t.timestamps
    end

    add_index :cap_and_redistribute_options, :weights, using: :gin, name: "index_cap_and_redistribute_options_on_weights_gin", if_not_exists: true
  end
end
