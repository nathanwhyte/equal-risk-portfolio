# frozen_string_literal: true

class CreateClosePrices < ActiveRecord::Migration[8.1]
  def change
    create_table :close_prices, id: :uuid do |t|
      t.string :ticker
      t.string :date
      t.float :close
    end

    add_index :close_prices, :ticker
  end
end
