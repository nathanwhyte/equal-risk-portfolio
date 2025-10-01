class CreatePortfolios < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolios do |t|
      t.string :name, null: false, default: "New Portfolio"
      t.string :userId
      t.text :stocks, array: true, null: false, default: []

      t.timestamps
    end
  end
end
