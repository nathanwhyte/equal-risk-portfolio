class CreateAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :allocations, id: :uuid do |t|
      t.timestamps
    end
  end
end
