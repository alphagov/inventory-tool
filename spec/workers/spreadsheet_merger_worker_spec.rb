require 'rails_helper'

describe SpreadsheetUpdaterWorker do
  let(:now) { Time.new(2016, 1, 11, 12, 26, 35, 0) }
  let(:in_the_past) { 5.days.ago }
  let(:inventory) { create :inventory, key: 'my-spreadsheet-key', name: 'My Spreadsheet', date_generated: in_the_past }
  let(:gs) {double(GoogleSpreadsheet, destroy: nil) }

  describe '#perform' do
    context 'valid search queries' do
      it 'updates the spreadsheet and marks the db record as generated' do
        Timecop.freeze(now) do
          expect(SpreadsheetUpdater).to receive(:new).and_return(double(SpreadsheetUpdater, update!: nil))

          worker = SpreadsheetUpdaterWorker.new
          worker.perform(inventory.id)

          inventory.reload
          expect(inventory.background_job_in_progress).to be false
          expect(inventory.flash_notes).to be_nil
          expect(inventory.date_generated).to eq now
        end
      end
    end

    context 'invalid seach queries' do
      it 'marks the db record and background job error' do
        Timecop.freeze(now) do
          updater = double(SpreadsheetUpdater)
          expect(SpreadsheetUpdater).to receive(:new).and_return(updater)
          expect(updater).to receive(:update!).and_raise(Rummager::SearchApiClientError, 'xxxxx')

          worker = SpreadsheetUpdaterWorker.new
          worker.perform(inventory.id)

          inventory.reload
          expect(inventory.background_job_in_progress).to be false
          expect(inventory.flash_notes).to eq 'xxxxx'
          expect(inventory.date_generated).to eq in_the_past
        end
      end
    end
  end
end
