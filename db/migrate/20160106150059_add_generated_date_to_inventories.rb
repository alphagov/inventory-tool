class AddGeneratedDateToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :date_generated, :datetime
  end
end
