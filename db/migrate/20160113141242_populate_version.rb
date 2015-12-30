class PopulateVersion < ActiveRecord::Migration
  def up
    execute("UPDATE inventories SET version = 1 WHERE is_skeleton = 'f'")
    execute("UPDATE inventories SET version = 2, key = '1PpwUgdqidkKRU6BuxeKxqpvyoCJ9khxcJLPg5W9FKVI' WHERE is_skeleton = 't'")
  end

  def down
    execute('UPDATE inventories SET version = NULL')
  end
end
