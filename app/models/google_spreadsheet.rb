
# This class uses the GoogleDrive API to manipulate spreadsheets.

# NOTE: Be sure to use the same handle for a worksheet until you save it.
#
# e.g. 
#   overview_worksheet[1,2] = 'this'
#   overview_worksheet[2,2] = 'that'
#   overview_worksheet.save
#
# will not work as expected, because each call gets a handle to the worksheet as it is on the google drive, not 
# how it is in your program's memory after you have manipulated it.  
#
# Instead, use this pattern:
#   ws = overview_worksheet
#   ws[1,2] = 'this'
#   ws[2,2] = 'that'
#   ws.save
#
class GoogleSpreadsheet

  SKELETON_KEY = '1PpwUgdqidkKRU6BuxeKxqpvyoCJ9khxcJLPg5W9FKVI'
  GOOGLE_DRIVE_CONFIG_FILE = "#{Rails.root}/config/google_drive_config.json"

  private_class_method :new


  def self.find_by_key(key)
    new(key: key)
  end

  def self.create_from_skeleton(title)
    new(title: title)
  end

  # Do not uses to create new GoogleSpreadsheets; use:
  # * GoogleSpreadsheet.find_by_key - retrieves an existing spreadsheet
  # * GoogleSpreadsheet.create_from_skeleton - creates a copy from the skeleton spreadsheet
  #
  def initialize(options)
    @session ||= GoogleCredentials.saved_session
    @inventory = nil
    if options.key?(:title)
      duplicate_skeleton(options[:title])
    elsif options.key?(:key)
      find_spreadsheet(options[:key])
    else
      raise ArgumentError.new("Invalid options passed to GoogleSpreadsheet.new")
    end
  end

  def inventory
    @inventory ||= Inventory.find_by!(key: key)
  end

  def delete!
    @spreadsheet.delete
  end

  def key
    @spreadsheet.key
  end

  def documents(inventory_id)
    ws = documents_worksheet
    rows = ws.rows(1)
    InventoryItemCollection.new_from_spreadsheet(inventory_id, rows)
  end

  def query_rows
    # return an array of query row objects
    ws = queries_worksheet
    ws.rows(1).map{ |row| QueryRow.new(row) }
  end

  def update(inventory_item_collection)
    presenter = InventoryItemCollectionPresenter.new(inventory_item_collection)
    clear_existing_documents
    set_max_rows(inventory_item_collection.size)
    ActivityLog.debug "Existing documents worksheet erased"
    ws = documents_worksheet
    row_number = 2
    presenter.present_in_chunks(chunk_size) do |chunk|
      ws.update_cells(row_number, 1, chunk)
      ws.save
      ActivityLog.debug "Wrote rows #{row_number} to #{row_number + chunk.size} to spreadhseet"
      row_number += chunk_size
    end
  end

  def calculate_overview_stats
    ws = overview_worksheet
    ws[1,2] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    ws[2,2] = num_queries
    ws[3,2] = num_documents
    ws[4,2] = num_docs_on_govuk
    ws.save
  end

private
  def set_max_rows(num_rows)
    num_rows += 2
    ws = documents_worksheet
    ws.max_rows = num_rows
    ws.save
  end

  def chunk_size
    500
  end

  def num_queries
    queries_worksheet.num_rows - 1
  end

  def num_documents
    documents_worksheet.num_rows - 1
  end

  def num_docs_on_govuk
    Rummager::SearchApiClient.num_docs_on_govuk
  end

  def clear_existing_documents
    ws = documents_worksheet
    ws.update_cells(2, 1, Array.new(ws.num_rows - 1, Array.new(ws.num_cols)))
    ws.save
  end

  def find_spreadsheet(key)
    @spreadsheet = @session.spreadsheet_by_key(key)
  end

  def overview_worksheet
    @spreadsheet.worksheet_by_title('Overview')
  end

  def documents_worksheet
    @spreadsheet.worksheet_by_title('Documents')
  end

  def queries_worksheet
    @spreadsheet.worksheet_by_title('Queries')
  end


  def duplicate_skeleton(new_title)
    skeleton = @session.spreadsheet_by_key(SKELETON_KEY)
    @spreadsheet = skeleton.copy(new_title)
    initialize_overview
    initialize_queries
    clear_existing_documents
    @spreadsheet.title = new_title
    @spreadsheet.acl.push(type: 'domain', value: 'digital.cabinet-office.gov.uk', role: 'writer')
  end

  def initialize_overview
    ws = overview_worksheet
    ws[1,2] = Date.today
    ws[2,2] = 0
    ws[3,2] = 0
    ws[4,2] = 0
    ws.save
  end

  def initialize_queries
    ws =  queries_worksheet
    ws[2,1] = ''
    ws[3,1] = ''
    ws.save
  end
 
end
