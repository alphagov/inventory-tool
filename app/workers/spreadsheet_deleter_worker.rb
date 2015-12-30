class SpreadsheetDeleterWorker < BaseWorker

  def perform(inventory_id)
    begin
      inventory = Inventory.find(inventory_id)
      log :info, inventory_id, "starting for spreadsheet '#{inventory.name}'"
      log :info, inventory_id, "Finding google spreadsheet with key '#{inventory.key}'"
      gs = GoogleSpreadsheet.find_by_key(inventory.key)
      gs.delete!
    rescue => err
      if err.is_a?(Google::APIClient::ClientError) && err.message =~ /^File not found/
        log :warn, inventory_id, "Spreadsheet '#{inventory.name}' could not be found.  Deleting the db record anyway."
        inventory.destroy
        log :info, inventory_id, "Db record deleted"
      else
        log_error inventory_id, err
        inventory.mark_background_job_error("#{err.class}: #{err.message}")
      end
    else
      inventory.destroy
      log :info, inventory_id, "Db record deleted"
    end

  end
end



