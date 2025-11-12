class CascadeDeletePortfolioReferences < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :allocations, :portfolios
    add_foreign_key :allocations, :portfolios, on_delete: :cascade

    remove_foreign_key :cap_and_redistribute_options, :portfolios
    add_foreign_key :cap_and_redistribute_options, :portfolios, on_delete: :cascade
  end
end
