require 'rails_helper'

RSpec.describe InventoriesController, type: :controller do
  def http_login
    username = 'test'
    password = 'test'
    request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end

  describe 'GET index' do
    it 'assigns inventories' do
      create :inventory, name: 'xxxx'
      create :inventory, name: 'aaaa'
      create :skeleton_inventory, name: 'skeleton'

      http_login
      get :index

      expect(assigns(:inventories).map(&:name)).to eq %w{ skeleton aaaa xxxx }
    end

    it 'assigns inventory' do
      http_login
      get :index

      inventory = assigns(:inventory)
      expect(inventory).to be_instance_of(Inventory)
      expect(inventory.new_record?).to be true
    end

    it 'renders the index template' do
      http_login
      get :index

      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end
  end

  describe 'POST create' do
    let(:spreadsheet) { double(GoogleSpreadsheet, key: 'my-spreadsheet-key') }

    it 'creates a pending record and queues a SpreadsheetCreatorWorker' do
      inventory = double(Inventory, id: 33, log: nil)
      allow(Inventory).to receive(:create_pending).and_return(inventory)
      allow(SpreadsheetCreatorWorker).to receive(:perform_async)

      http_login
      post :create, inventory: {name: 'xyz'}

      expect(Inventory).to have_received(:create_pending).with('xyz')
      expect(SpreadsheetCreatorWorker).to have_received(:perform_async).with(33, 'xyz')
      expect(inventory).to have_received(:log).with(:info, "Inventory record created for spreadsheet 'xyz'")
    end

    it 'redirects to the index page' do
      inventory = double(Inventory, id: 33, log: nil)
      allow(Inventory).to receive(:create_pending).and_return(inventory)
      allow(SpreadsheetCreatorWorker).to receive(:perform_async)

      http_login
      post :create, inventory: {name: 'xyz'}

      expect(flash[:warning]).to eq "Creation of new spreadsheet 'xyz' has been scheduled. Refresh later to view."
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(inventories_path)
      expect(inventory).to have_received(:log).with(:info, "Inventory record created for spreadsheet 'xyz'")
    end

    it 'errrors if name already exists' do
      create :inventory, name: 'abc'

      http_login
      post :create, inventory: {name: 'abc'}

      expect(flash).not_to be_empty
      expect(flash[:danger]).to eq 'Error: A Spreadsheet with that name already exists.  Choose another name.'
      expect(response).to render_template('index')
    end
  end

  describe 'PATCH update' do
    let(:inventory) { create :inventory }
    let(:updater) { double SpreadsheetUpdater }

    before(:each) do
      allow(SpreadsheetUpdaterWorker).to receive(:perform_async)
    end

    it 'queues a background job' do
      http_login
      patch :update, id: inventory.id

      expect(SpreadsheetUpdaterWorker).to have_received(:perform_async).with(inventory.id)
    end

    it 'marks the inventory record as a background job in progress' do
      http_login
      patch :update, id: inventory.id

      inv = Inventory.find(inventory.id)

      expect(inv.background_job_in_progress).to be true
      expect(inv.flash_notes).to match(/^Regenerating Queries \(started \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\). Refresh in a few minutes to view/)
    end

    it 'redirects to the inventories path' do
      http_login
      patch :update, id: inventory.id

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(inventories_path)
    end
  end

  describe 'DELETE destroy' do
    let(:inventory) { create :inventory, name: 'Deletable Spreadsheet' }

    before(:each) do
      allow(SpreadsheetDeleterWorker).to receive(:perform_async)
    end

    it 'starts a background job' do
      http_login
      delete :destroy, id: inventory.id

      inv = Inventory.find(inventory.id)
      expect(inv.background_job_in_progress).to be true
      expect(inv.flash_notes).to eq "Queued for deletion."
    end

    it 'queues a SpreadsheetDeleterWorkerJob' do
      http_login
      delete :destroy, id: inventory.id

      expect(SpreadsheetDeleterWorker).to have_received(:perform_async).with(inventory.id)
    end

    it 'updates the flash message' do
      http_login
      delete :destroy, id: inventory.id

      expect(flash[:danger]).to eq "Spreadsheet 'Deletable Spreadsheet' has been queued for deletion."
    end
  end
end
