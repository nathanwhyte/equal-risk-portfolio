class AddAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :portfolios, :allocations, :jsonb
  end
end
