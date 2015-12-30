require 'rails_helper'

describe SpreadsheetDeleterWorker do
  let(:inventory) { create :inventory, key: 'my-spreadsheet-key', name: 'My Spreadsheet' }
  let(:gs) {double(GoogleSpreadsheet, destroy: nil) }

  context 'spreadsheet exists' do

    it 'deletes the spreadsheet and the database record' do
      expect(GoogleSpreadsheet).to receive(:find_by_key).with('my-spreadsheet-key').and_return(gs)
      expect(gs).to receive(:delete!)

      worker = SpreadsheetDeleterWorker.new
      worker.perform(inventory.id)

      expect(Inventory.where(id: inventory.id)).to be_empty
      logs = ActivityLog.where(inventory_id: inventory.id)
      expect(logs.map(&:level)).to eq %W{ INFO INFO INFO }
      expect(logs.map(&:message)).to eq(
        [
          "SpreadsheetDeleterWorker: starting for spreadsheet 'My Spreadsheet'",
          "SpreadsheetDeleterWorker: Finding google spreadsheet with key 'my-spreadsheet-key'",
          "SpreadsheetDeleterWorker: Db record deleted",
        ]
      )
    end
  end

  context 'spreadsheet doesnt exist' do
    it 'deletes the db record and logs a warning' do
      expect(GoogleSpreadsheet).to receive(:find_by_key).with('my-spreadsheet-key').and_raise(Google::APIClient::ClientError, 'File not found')

      worker = SpreadsheetDeleterWorker.new
      worker.perform(inventory.id)

      expect(Inventory.where(id: inventory.id)).to be_empty
      logs = ActivityLog.where(inventory_id: inventory.id)
      expect(logs.map(&:level)).to eq %W{ INFO INFO WARN INFO }
      expect(logs.map(&:message)).to eq(
        [
          "SpreadsheetDeleterWorker: starting for spreadsheet 'My Spreadsheet'",
          "SpreadsheetDeleterWorker: Finding google spreadsheet with key 'my-spreadsheet-key'",
          "SpreadsheetDeleterWorker: Spreadsheet 'My Spreadsheet' could not be found.  Deleting the db record anyway.",
          "SpreadsheetDeleterWorker: Db record deleted",
        ]
      )
    end
  end

  context 'unknown error accessing spreadsheet' do
    it 'save a a message in the db record flash notes' do
      expect(GoogleSpreadsheet).to receive(:find_by_key).with('my-spreadsheet-key').and_raise(ArgumentError, 'Unexpected error')

      worker = SpreadsheetDeleterWorker.new
      worker.perform(inventory.id)

      inventory.reload
      expect(inventory.background_job_in_progress).to be false
      expect(inventory.flash_notes).to match /ArgumentError: Unexpected error/

      logs = ActivityLog.where(inventory_id: inventory.id)
      expect(logs.size).to eq 3
      expect(logs[0].level).to eq 'INFO'
      expect(logs[0].message).to eq "SpreadsheetDeleterWorker: starting for spreadsheet 'My Spreadsheet'"
      expect(logs[1].level).to eq 'INFO'
      expect(logs[1].message).to eq "SpreadsheetDeleterWorker: Finding google spreadsheet with key 'my-spreadsheet-key'"
      expect(logs[2].level).to eq 'ERROR'
      expect(logs[2].message).to match(/^SpreadsheetDeleterWorker: ArgumentError: Unexpected error/)
    end
  end
  
end
