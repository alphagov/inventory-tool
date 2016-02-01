class SpreadsheetMigratorWorker
  V1_FIELD_POSITIONS = [ :url, :title, :last_updated,
    :format, :display_type, :document_type, :topics, :mainstream_browse_pages,
    :organisations, :policies, :document_collections, :is_withdrawn, :in_history_mode,
    :first_published_date, :matching_queries, :recommendation, :redirect_combine_url, :notes ]

  FIELD_POSITIONS = [ :title, :url, :description, :first_published_date, :last_updated,
    :organisations, :format, :display_type, :policies, :topics, :mainstream_browse_pages,
    :document_collections, :is_withdrawn, :in_history_mode, :matching_queries,
    :recommendation, :redirect_combine_url, :notes ]

  COLUMN_HEADINGS = [
    'Title',
    'Link',
    'Description',
    'First Published',
    'Last Updated',
    'Organisations',
    'Content Type',
    'Display Type',
    'Policies',
    'Topics',
    'Mainstream Categories',
    'Collections',
    'Withdrawn',
    'History mode',
    'Matching queries',
    'Recommendation',
    'Redirect or combine with which URL',
    'Notes',
  ]

  SKELETON_KEY = '1PpwUgdqidkKRU6BuxeKxqpvyoCJ9khxcJLPg5W9FKVI'

  def run
    invs = Inventory.where(version: 1)
    invs.each do |inv|
      puts ">>>>>>>>>>>>>> PROCESSING #{inv.name} <<<<<<<< #{__FILE__}::#{__LINE__} <<<<<<<<<\n"
      migrate(inv.id)
    end
  end

private
  def migrate(inventory_id)
    inventory = Inventory.find inventory_id
    inventory.log(:warn, "Migrating #{inventory.name} from old format to new format")
    session = GoogleCredentials.saved_session

    # make a copy and change the title of the old spreadsheet
    v1_spreadsheet = session.spreadsheet_by_key(inventory.key)
    v2_spreadsheet = v1_spreadsheet.copy("_NEW_#{v1_spreadsheet.title}")

    # erase the documents worksheet
    ws = v2_spreadsheet.worksheet_by_title('Documents')
    ws.delete

    # create a new documents worksheet
    ws = v2_spreadsheet.add_worksheet('Documents')

    # update the spreadsheet with the new column titles
    new_rows = []
    new_rows << COLUMN_HEADINGS

    v1_ws = v1_spreadsheet.worksheet_by_title('Documents')
    v1_ws.rows(1).each { |row| new_rows << transform_row(row) }
    ws.update_cells(1,1, new_rows)
    ws.save

    # rename spreadsheets
    v1_spreadsheet.title = "_OLD_#{v1_spreadsheet.title}"
    inventory.name = v1_spreadsheet.title
    inventory.save!

    v2_spreadsheet.title = v2_spreadsheet.title.sub(/^_NEW_/, '')
    Inventory.create(name: v2_spreadsheet.title, key: v2_spreadsheet.key, is_skeleton: false, version: 2)
  end

private
  def transform_row(row)
    new_row = []
    FIELD_POSITIONS.each do |fieldname|
      if fieldname == :description
        new_row << ""
      else
        index = V1_FIELD_POSITIONS.index(fieldname)
        new_row << row[index]
      end
    end
    new_row
  end
end
