# frozen_string_literal: true

class CreateAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :allocations do |t|
      t.references :portfolio, null: false, foreign_key: true, index: true, type: :uuid

      t.string :name, null: false
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    # Add unique index for allocation names per portfolio
    add_index :allocations, [ :portfolio_id, :name ], unique: true, name: "index_allocations_on_portfolio_id_and_name"

    # Add check constraint for percentage range
    add_check_constraint :allocations, "percentage > 0 AND percentage <= 100", name: "allocations_percentage_range"
  end
end
