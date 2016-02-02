class DropTableActivityLogs < ActiveRecord::Migration
  def up
    drop_table :activity_logs
  end

  def down
    create_table :activity_logs do |t|
      t.integer :inventory_id
      t.string :level
      t.text :message

      t.timestamps
    end
  end
end
