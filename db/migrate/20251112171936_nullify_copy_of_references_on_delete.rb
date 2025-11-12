class NullifyCopyOfReferencesOnDelete < ActiveRecord::Migration[8.1]
  def up
    # Find the foreign key constraint name dynamically
    fk = foreign_key_for(:portfolios, :portfolios, column: :copy_of_id)
    if fk
      remove_foreign_key :portfolios, name: fk.name
    end
    add_foreign_key :portfolios, :portfolios, column: :copy_of_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :portfolios, :portfolios, column: :copy_of_id
    # Restore the original foreign key without on_delete option (defaults to restrict)
    add_foreign_key :portfolios, :portfolios, column: :copy_of_id
  end

  private

  def foreign_key_for(from_table, to_table, column:)
    connection.foreign_keys(from_table).find do |fk|
      fk.to_table == to_table.to_s && fk.column == column.to_s
    end
  end
end
