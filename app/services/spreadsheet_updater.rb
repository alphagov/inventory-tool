class SpreadsheetUpdater
  def initialize(inventory)
    @inventory = inventory
  end

  def update!
    spreadsheet = GoogleSpreadsheet.find_by_key(@inventory.key)

    google_iic = spreadsheet.documents(@inventory.id)

    govuk_iic = InventoryItemCollection.new_from_search_queries(
      @inventory,
      spreadsheet.query_rows
    )

    @inventory.log :info, "Starting merge"

    google_iic.merge_collections!(govuk_iic)

    @inventory.log :info, "Merge complete - rewriting data back to spreadsheet"

    spreadsheet.update(google_iic)

    spreadsheet.calculate_overview_stats

    @inventory.log :info, "Update complete"
  end
end
