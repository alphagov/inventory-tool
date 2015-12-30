class AddVersionToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :version, :integer
  end
end
