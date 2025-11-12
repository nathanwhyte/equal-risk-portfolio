# frozen_string_literal: true

class CreatePortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolios, id: :uuid do |t|
      t.string :name
      t.jsonb :tickers
      t.jsonb :weights
      t.references :copy_of, foreign_key: { to_table: :portfolios }, type: :uuid

      t.timestamps
    end
  end
end
