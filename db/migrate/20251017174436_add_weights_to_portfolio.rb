class AddWeightsToPortfolio < ActiveRecord::Migration[8.0]
  def change
    add_column :portfolios, :weights, :jsonb, default: {}
  end
end
