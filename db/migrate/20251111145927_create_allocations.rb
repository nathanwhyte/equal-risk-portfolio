class CreateAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :allocations, if_not_exists: true do |t|
      t.timestamps
    end
  end
end
