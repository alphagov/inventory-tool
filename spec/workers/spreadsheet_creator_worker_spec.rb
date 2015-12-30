require 'rails_helper'

describe SpreadsheetCreatorWorker do
  describe '#perform' do

    let(:inventory)  { Inventory.create_pending('My new spreadsheet') }
    let(:gs) { double(GoogleSpreadsheet, key: 'my-new-spreadsheet-key') }
    let(:frozen_time) { Time.new(2016, 1, 10, 7, 24, 0, 0) }

    context 'successful creation' do
      before(:each) do
        allow(GoogleSpreadsheet).to receive(:create_from_skeleton).and_return(gs)
        allow(Sidekiq.logger).to receive(:info)
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

      it 'logs activity' do
        logs = ActivityLog.all
        expect(logs.size).to eq 3
        expect(logs.map(&:level)).to eq (%w{ INFO INFO INFO })
        expect(logs.map(&:message)).to eq (
          [
            "SpreadsheetCreatorWorker: starting for spreadsheet 'My new spreadsheet'",
            "SpreadsheetCreatorWorker: Google spreadsheet created from skeleton with key my-new-spreadsheet-key",
            "SpreadsheetCreatorWorker: Inventory record marked as complete with key 'my-new-spreadsheet-key'",
          ]
        )
      end
    end

    context 'exception during spreadsheet creation' do
      before(:each) do
        expect(GoogleSpreadsheet).to receive(:create_from_skeleton).and_raise(RuntimeError, "Dummy Error")
      end

      it 'logs the error' do
        worker = SpreadsheetCreatorWorker.new
        worker.perform(inventory.id, inventory.name)

        logs = ActivityLog.where(inventory_id: inventory.id)
        expect(logs.size).to eq 2
        expect(logs.first.level).to eq 'INFO'
        expect(logs.first.message).to eq "SpreadsheetCreatorWorker: starting for spreadsheet 'My new spreadsheet'"
        expect(logs.last.level).to eq 'ERROR'
        expect(logs.last.message).to match /^SpreadsheetCreatorWorker: RuntimeError: Dummy Error/
      end
    end
  end
end
