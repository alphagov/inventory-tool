class AddFlashNotesToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :flash_notes, :string
  end
end
