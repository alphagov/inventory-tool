class CreateActivityLogs < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.integer :inventory_id
      t.string :level
      t.text :message

      t.timestamps
    end
  end
end
