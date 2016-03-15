require 'rails_helper'

describe SpreadsheetCreatorWorker do
  describe '#perform' do
    let(:inventory) { Inventory.create_pending('My new spreadsheet') }
    let(:gs) { double(GoogleSpreadsheet, key: 'my-new-spreadsheet-key') }
    let(:frozen_time) { Time.new(2016, 1, 10, 7, 24, 0, 0) }

    context 'successful creation' do
      before(:each) do
        allow(GoogleSpreadsheet).to receive(:create_from_skeleton).and_return(gs)
        Timecop.freeze(frozen_time) do
          worker = SpreadsheetCreatorWorker.new
          worker.perform(inventory.id, inventory.name)
        end
      end

      it 'creates a new GoogleSpreadsheet' do
        expect(GoogleSpreadsheet).to have_received(:create_from_skeleton).with('My new spreadsheet')
      end

      it 'updates the inventory record' do
        inv = Inventory.find(inventory.id)
        expect(inv.background_job_in_progress).to be false
        expect(inv.flash_notes).to be_nil
        expect(inv.date_generated).to eq frozen_time
      end
    end
  end
end
