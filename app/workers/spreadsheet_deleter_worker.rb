class SpreadsheetDeleterWorker < BaseWorker
  def perform(inventory_id)
    begin
      inventory = Inventory.find(inventory_id)
      log :info, inventory_id, "starting for spreadsheet '#{inventory.name}'"
      log :info, inventory_id, "Finding google spreadsheet with key '#{inventory.key}'"
      gs = GoogleSpreadsheet.find_by_key(inventory.key)
      gs.delete!
      inventory.destroy
    rescue Google::APIClient::ClientError => e
      if e.message =~ /^File not found/
        log :warn, inventory_id, "Spreadsheet '#{inventory.name}' could not be found. Deleting the db record anyway."
        inventory.destroy
      else
        raise(e)
      end
    end
  end
end
