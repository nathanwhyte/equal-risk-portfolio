class CreatePortfolios < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolios, id: :uuid do |t|
      t.string :name
      t.jsonb :tickers
      t.jsonb :weights

      t.timestamps
    end
  end
end
