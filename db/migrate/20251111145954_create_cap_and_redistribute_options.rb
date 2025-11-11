class CreateCapAndRedistributeOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :cap_and_redistribute_options, if_not_exists: true do |t|
      t.references :portfolio, null: false, foreign_key: true, index: true, type: :uuid

      t.decimal :cap_percentage, precision: 4, scale: 3, null: false
      t.integer :top_n, null: false
      t.boolean :active, null: false, default: false
      t.jsonb :weights, null: false, default: {}

      t.timestamps
    end

    add_index :cap_and_redistribute_options, :weights, using: :gin, name: "index_cap_and_redistribute_options_on_weights_gin", if_not_exists: true

    # Add check constraints for data integrity
    add_check_constraint :cap_and_redistribute_options, "cap_percentage > 0 AND cap_percentage <= 1", name: "cap_percentage_range"
    add_check_constraint :cap_and_redistribute_options, "top_n > 0", name: "top_n_positive"
  end
end
