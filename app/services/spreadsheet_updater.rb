class SpreadsheetUpdater
  def initialize(inventory)
    @inventory = inventory
    @spreadsheet = GoogleSpreadsheet.find_by_key(@inventory.key)
    @query_rows = @spreadsheet.query_rows
    @google_iic = @spreadsheet.documents(inventory.id)
    @govuk_iic = InventoryItemCollection.new_from_search_queries(@inventory, @query_rows)
    @inventory.log :info, "#{self.class} initialized"
  end

  def update!
    @inventory.log :info, "#{self.class} starting merge"
    @google_iic.merge_collections!(@govuk_iic)
    @inventory.log :info, "#{self.class} merge complete - rewriting data back to spreadsheet"
    @spreadsheet.update(@google_iic)
    @spreadsheet.calculate_overview_stats
    @inventory.log :info, "#{self.class} update complete"
  end
end
