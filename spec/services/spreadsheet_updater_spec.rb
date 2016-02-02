require 'rails_helper'

describe SpreadsheetUpdater do
  context 'updating the spreadsheet' do
    it 'should load item collections from the spreadsheet and the queries' do
      inventory = create :inventory, key: 'my-key'
      gs = double GoogleSpreadsheet
      google_iic = double 'InventoryItemCollection from google spreadsheet'
      govuk_iic = double 'InventoryItemCollection from search results'
      query_row_1 = double QueryRow, query: 'Early years'
      query_row_2 = double QueryRow, query: 'Late years'

      expect(GoogleSpreadsheet).to receive(:find_by_key).with("my-key").and_return(gs)
      expect(gs).to receive(:query_rows).and_return([ query_row_1, query_row_2 ])
      expect(gs).to receive(:documents).and_return(google_iic)
      expect(InventoryItemCollection).to receive(:new_from_search_queries).with(inventory, [query_row_1, query_row_2]).and_return(govuk_iic)

      su = SpreadsheetUpdater.new(inventory)

      expect(google_iic).to receive(:merge_collections!).with(govuk_iic)
      expect(gs).to receive(:update).with(google_iic)
      expect(gs).to receive(:calculate_overview_stats)

      su.update!
    end
  end
end
