class AddCopyOfToPortfolios < ActiveRecord::Migration[8.1]
  def change
    add_reference :portfolios, :copy_of, foreign_key: { to_table: :portfolios }, type: :uuid
  end
end
