class SpreadsheetCreatorWorker < BaseWorker
  def perform(inventory_id, name)
    begin
      log :info, inventory_id, "starting for spreadsheet '#{name}'"
      gs = GoogleSpreadsheet.create_from_skeleton(name)
      log :info, inventory_id, "Google spreadsheet created from skeleton with key #{gs.key}"
      Inventory.find(inventory_id).mark_creation_complete(gs.key)
      log :info, inventory_id, "Inventory record marked as complete with key '#{gs.key}'"
    end
  end
end
