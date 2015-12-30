class AddBackgroundJobInProgressToInventories < ActiveRecord::Migration
  def change
    add_column :inventories, :background_job_in_progress, :boolean, default: false
  end
end
