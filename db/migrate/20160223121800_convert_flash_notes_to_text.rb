class ConvertFlashNotesToText < ActiveRecord::Migration
  def up
    change_column :inventories, :flash_notes, :text
  end
end
