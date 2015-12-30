class InventoryItem
  include ActiveModel::Model
  include Comparable

  GOVUK_BASE_URL = 'https://www.gov.uk'

  # maps incoming fields in the spreadsheet row to attributes on this model
  V1_FIELD_POSITIONS = [ :url, :title, :last_updated,
    :format, :display_type, :document_type, :topics, :mainstream_browse_pages,
    :organisations, :policies, :document_collections, :is_withdrawn, :in_history_mode, 
    :first_published_date, :matching_queries, :recommendation, :redirect_combine_url, :notes ]

  FIELD_POSITIONS = [ :title, :url, :description, :first_published_date, :last_updated, 
    :organisations, :format, :display_type, :policies, :topics, :mainstream_browse_pages, :document_collections,
    :is_withdrawn, :in_history_mode, :matching_queries, :recommendation, :redirect_combine_url, :notes ]

  # fields on this model that can be updated from an InventoryItem created from a more recent search
  UPDATABLE_FIELDS = [ :title, :last_updated, :format, :display_type, :description,
    :is_withdrawn, :in_history_mode, :first_published_date]

  # fields on this model which should be merged with an InventoryItem created from a more recent search
  MERGEABLE_FIELDS = [ :topics, :mainstream_browse_pages, :organisations, :policies, :document_collections, :matching_queries]

  # fields that are transformed into an array
  ARRAY_FIELDS = [ :topics, :mainstream_browse_pages, :organisations, :policies, :document_collections, :matching_queries ]

  BOOLEAN_FIELDS = { :is_withdrawn => 'Withdrawn', :in_history_mode => "History mode" }

  ARRAY_SEPARATOR = '; '

  # extra fields we ask for from rummager when doing the search query
  ADDITIONAL_QUERY_FIELDS = [ :link, :title, :description, :public_timestamp, :format, :display_type,  
    :topics, :mainstream_browse_pages, :organisations, :policies, :document_collections ].join(',')

  attr_accessor *FIELD_POSITIONS

  private_class_method :new

  def self.new_from_spreadsheet_row(inventory_id, row)
    ActivityLog.debug "Creating Inventory item from spreadsheet row for #{row[0]}", inventory_id
    params = {}
    row.each_with_index do |data_item, i|
      field_name = FIELD_POSITIONS[i]
      if is_array_field?(field_name)
        params[field_name] = make_array(data_item)
      elsif is_boolean_field?(field_name)
        params[field_name] = make_boolean(field_name, data_item)
      else
        params[field_name] = data_item
      end
    end
    params[:url] = row[1].sub(GOVUK_BASE_URL, '')
    InventoryItem.send(:new, params)
  end

  def self.new_from_search_result(doc, query_name)
    item = InventoryItem.send(:new)
    item.populate_from_search_result(doc, query_name)
    item
  end

  def populate_from_search_result(doc, query_name)
    @url = doc['link'].nil? ? "No link for #{doc.inspect}" : doc['link'] 
    @title = extract_field(doc, 'title')
    @description = doc['description']
    @last_updated = doc['public_timestamp'].nil? ? nil : Time.parse(doc['public_timestamp']) 
    @format = extract_field(doc, 'format').humanize
    @display_type = extract_field(doc, 'display_type', 'None')
    @topics = extract_from_array_of_hashes(doc, 'topics', 'title', 'slug')
    @mainstream_browse_pages = doc['mainstram_browse_page'] || []
    @organisations = extract_from_array_of_hashes(doc, 'organisations', 'acronym')
    @policies = doc['policies'].nil? ? [] : doc['policies'].sort
    @document_collections = extract_from_array_of_hashes(doc, 'document_collections', 'title', 'slug')
    @is_withdrawn = false
    @in_history_mode = false
    @first_published_date = 'Unknown'
    @matching_queries = [query_name]
    @recommendation = ''
    @redirect_combine_url = ''
    @notes = ''
  end

  def <=>(other)
    @url <=> other.url
  end

  # updates this item with an Inventory Item from a more recent search
  def update_from_other_item(other_item)
    update_updatable_fields(other_item)
    update_mergeable_fields(other_item)
    remove_not_returned
  end

  def mark_as_missing
    unless @notes =~ /Not returned from search as of/
      @notes = "Not returned from search as of #{Time.now.strftime('%Y-%m-%d %H:%M')}; " + @notes.to_s
    end
  end

private
  def remove_not_returned
    @notes.gsub!(/Not returned from search as of .*;\s/, '')
  end
  
  def update_updatable_fields(other_item)
    UPDATABLE_FIELDS.each do |fieldname|
      send(putter_method(fieldname), other_item.send(fieldname))
    end
  end

  def update_mergeable_fields(other_item)
    MERGEABLE_FIELDS.each do |fieldname|
      new_value = merge_arrays(other_item, fieldname)
      delete_matching_query_row_numbers(new_value) if fieldname == :matching_queries
      send(putter_method(fieldname), new_value)
    end
  end

  # This is here just to help the switch over from matching query row numbers to matching query names
  # can be removed once all spreadsheets with matching query row numbers have been re-generated
  #
  def delete_matching_query_row_numbers(matching_queries)
    matching_queries.delete_if{ |x| x =~ /^[0-9]+$/ }
  end

  def putter_method(fieldname)
    "#{fieldname}=".to_sym
  end

  def merge_arrays(other_item, fieldname)
    (send(fieldname) | other_item.send(fieldname)).sort
  end

  def extract_field(doc, fieldname, nil_value = 'Unknown')
    if doc[fieldname].nil?
      nil_value
    else
      doc[fieldname]
    end
  end

  def self.is_boolean_field?(fieldname)
    BOOLEAN_FIELDS.keys.include?(fieldname)
  end

  def self.make_boolean(fieldname, data_field)
    true_value = BOOLEAN_FIELDS[fieldname]
    data_field == true_value ? true : false
  end

  def self.is_array_field?(fieldname)
    ARRAY_FIELDS.include?(fieldname)
  end

  def self.make_array(data_field)
    data_field.split(ARRAY_SEPARATOR)
  end

  # returns a list of values for <field> in an array of hashes which is keyed by <element>, in the outer hash <doc>
  def extract_from_array_of_hashes(doc, element, field, fallback_field = 'title')
    return [] if doc[element].nil?
    
    result = []
    doc[element].each do |inner_hash|
      key = inner_hash.key?(field) ? field : fallback_field
      if inner_hash.key?(key)
        result << capitalize_first(inner_hash[key])
      else
        result << "No #{field} or #{fallback_field} in search results"
      end
    end
    result.sort
  end

  def capitalize_first(string)
    string.slice(0,1).capitalize + string.slice(1..-1)
  end

end




















