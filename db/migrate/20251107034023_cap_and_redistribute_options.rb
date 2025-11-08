class CapAndRedistributeOptions < ActiveRecord::Migration[8.1]
  def change
    add_column :portfolio_versions, :cap_percentage, :float, default: nil
    add_column :portfolio_versions, :top_n, :integer, default: nil
  end
end
