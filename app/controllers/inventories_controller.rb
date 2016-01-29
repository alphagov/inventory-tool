class InventoriesController < ApplicationController
  http_basic_authenticate_with name: ENV["USERNAME"], password: ENV["PASSWORD"]

  def index
    @inventories = Inventory.all_ordered
    @inventory = Inventory.new
  end

  def create
    name = params['inventory']['name']
    ActivityLog.info "Creation of spreadsheet '#{name}' requested"
    if Inventory.exist?(name)
      flash[:danger] = "Error: A Spreadsheet with that name already exists.  Choose another name."
      ActivityLog.warn "Spreadsheet '#{name}' could not be created - a spreadsheet with that name already exists"
      @inventories = Inventory.all_ordered
      @inventory = Inventory.new(name: name)
      render action: 'index'
    else
      inventory = Inventory.create_pending(name)
      inventory.log(:info, "Inventory record created for spreadsheet '#{name}'")
      SpreadsheetCreatorWorker.perform_async(inventory.id, name)
      inventory.log(:info, "SpreadsheetCreatorWorker.peform_async(#{inventory.id}, '#{name}') queued.")
      flash[:warning] = "Creation of new spreadsheet '#{name}' has been scheduled. Refresh later to view."
      redirect_to inventories_path
    end
  end

  def update
    inventory = Inventory.find(params[:id])
    inventory.start_background_job!("Regenerating Queries (started #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}). Refresh in a few minutes to view")
    inventory.log(:info, "Regeneration requested for spreadsheet '#{inventory.name}'")
    SpreadsheetMergerWorker.perform_async(inventory.id)
    inventory.log(:info, "SpreadsheetMergerWorker.perform_async(#{inventory.id})")
    flash[:warning] = "A background job to regenerate the queries for '#{inventory.name}' has been started"
    redirect_to inventories_path
  end

  def destroy
    inventory = Inventory.find(params['id'])
    inventory.log(:info, "Deletion requested for spreadsheet '#{inventory.name}'")
    inventory.start_background_job!("Queued for deletion.")
    SpreadsheetDeleterWorker.perform_async(inventory.id)
    inventory.log(:info, "SpreadsheetDeleterWorker.perform_async(#{inventory.id})")
    flash[:danger] = "Spreadsheet '#{inventory.name}' has been queued for deletion."
    redirect_to inventories_path
  end
end
