require 'rails_helper'

describe 'DatabasePruner' do
  
  describe 'run' do
    it 'should delete all debug and all records referring to non-existent inventories older than 36 hours' do
      inv = create :inventory
      create :activity_log, message: 'al01', level: 'DEBUG', inventory_id: inv.id # keep - DEBUG within 36 hours
      create :activity_log, message: 'al02', level: 'ERROR', inventory_id: inv.id # keep - not DEBUG
      create :activity_log, message: 'al03', level: 'WARN', inventory_id: inv.id # keep - not DEBUG
      create :activity_log, message: 'al04', level: 'WARN', inventory_id: (inv.id + 100) # delete - non-existent inventory
      create :activity_log, message: 'al05', level: 'DEBUG', inventory_id: (inv.id + 100) # delete - non-existent inventory
      create :activity_log, message: 'al06', level: 'ERROR', inventory_id: (inv.id + 100) # delete - non-existent inventory
      create :activity_log, message: 'al07', level: 'WARN', inventory_id: (inv.id + 100) # delete - non-existent inventory
      create :activity_log, message: 'al08', level: 'WARN', inventory_id: (inv.id + 100) # delete - non-existent inventory

      Timecop.freeze(40.hours.ago) do
        create :activity_log, message: 'al11', level: 'DEBUG', inventory_id: inv.id # delete - DEBUG more than 36 hours ago
        create :activity_log, message: 'al12', level: 'ERROR', inventory_id: inv.id # keep - not DEBUG
        create :activity_log, message: 'al13', level: 'WARN', inventory_id: inv.id # keep - not DEBUG
        create :activity_log, message: 'al14', level: 'WARN', inventory_id: (inv.id + 100) # delete - non-existent inventory
        create :activity_log, message: 'al15', level: 'DEBUG', inventory_id: (inv.id + 100) # delete - non-existent inventory
        create :activity_log, message: 'al16', level: 'ERROR', inventory_id: (inv.id + 100) # delete - non-existent inventory
        create :activity_log, message: 'al17', level: 'WARN', inventory_id: (inv.id + 100) # delete - non-existent inventory
        create :activity_log, message: 'al18', level: 'WARN', inventory_id: (inv.id + 100) # delete - non-existent inventory
      end

      Timecop.freeze(50.hours.ago) do
        create :activity_log, message: 'al22', level: 'ERROR', inventory_id: inv.id # delete - more than 48 hours old
        create :activity_log, message: 'al23', level: 'WARN', inventory_id: inv.id # delete - more than 48 hours old
      end

      expect(ActivityLog.count).to eq 18

      DatabasePruner.new.run

      logs = ActivityLog.all.order(:id)
      expect(logs.size).to eq 6
      expect(logs[0].message).to eq 'al01'
      expect(logs[1].message).to eq 'al02'
      expect(logs[2].message).to eq 'al03'
      expect(logs[3].message).to eq 'al12'
      expect(logs[4].message).to eq 'al13'
      expect(logs.last.level).to eq 'DEBUG'
      expect(logs.last.message).to eq 'Database pruned, number of activity logs reduced from 18 to 5'

    end
  end

end
