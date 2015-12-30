class CreateInventories < ActiveRecord::Migration
  def change
    create_table :inventories do |t|
      t.string :name
      t.string :key
      t.boolean :is_skeleton, default: false

      t.timestamps
    end
  end
end
