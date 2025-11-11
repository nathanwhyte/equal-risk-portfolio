class CreateCapAndRedistributeOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :cap_and_redistribute_options, id: :uuid do |t|
      t.timestamps
    end
  end
end
