class DropVersionColumn < ActiveRecord::Migration
  def change
    remove_column :inventories, :version
  end
end
