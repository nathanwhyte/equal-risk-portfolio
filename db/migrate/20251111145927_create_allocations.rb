class CreateAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :allocations, if_not_exists: true do |t|
      t.references :portfolio, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.float :percentage, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end
  end
end
