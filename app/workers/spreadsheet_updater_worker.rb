class SpreadsheetUpdaterWorker < BaseWorker
  def perform(inventory_id)
    inventory = Inventory.find(inventory_id)

    begin
      log :info, inventory_id, "Starting for spreadsheet '#{inventory.name}'"
      updater = SpreadsheetUpdater.new(inventory)
      log :info, inventory.id, "Spreadsheet Updater created for Inventory #{inventory_id}"
      updater.update!
      log :info, inventory.id, "Spreadsheet Updated for Inventory #{inventory_id}"
      inventory.mark_generated
    rescue Rummager::SearchApiClientError => err
      log :warn, inventory.id, "SearchApiClientError: #{err.message}"
      inventory.mark_background_job_error(err.message)
    rescue => err
      log_error inventory_id, err
    end
  end
end
