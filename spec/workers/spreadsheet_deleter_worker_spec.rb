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
    end
  end

  context 'spreadsheet doesnt exist' do
    it 'deletes the db record' do
      expect(GoogleSpreadsheet).to receive(:find_by_key).with('my-spreadsheet-key').and_raise(Google::APIClient::ClientError, 'File not found')

      worker = SpreadsheetDeleterWorker.new
      worker.perform(inventory.id)

      expect(Inventory.where(id: inventory.id)).to be_empty
    end
  end
end
