class InventoryItemCollection
  extend Forwardable

  def_delegators :@collection, :size

  attr_reader :collection, :source

  private_class_method :new

  def initialize(source)
    raise ArgumentError.new("Source must be :query or :sheet") unless [:query, :sheet].include?(source)
    @source = source
    @collection = {}
  end

  def self.new_from_spreadsheet(inventory_id, array_of_rows)
    ActivityLog.debug ">>>>>>>>>>>>>>>> new from spreadsheet <<<<<<<<<<<<<<<<<<"    
    iic = new(:sheet)
    array_of_rows.each do |row|
      item = InventoryItem.new_from_spreadsheet_row(inventory_id, row)
      iic.add_unique_item(item, inventory_id)
    end
    iic
  end

  def self.new_from_search_queries(inventory, query_rows)
    ActivityLog.debug ">>>>>>>>>>>>>>>> new from spreadsheet queries: #{@query_rows.inspect} <<<<<<<<<<<<<<<<<<"    
    inventory.log :info, "#{self} instantiating from queries"
    iic = new(:query)
    query_rows.each_with_index do |query_row, index|
      ActivityLog.debug  "instantiating search client with #{query_row.query}", inventory.id
      search_results = Rummager::SearchApiClient.new(inventory.id, query_row.query).search
      inventory.log :info, "#{self} Adding #{search_results.size} results from query #{query_row.name}"
      iic.add_search_results(search_results, query_row.name)
    end
    iic
  end

  def add_search_results(search_results, query_name)
    search_results.each do |search_result|
      item = InventoryItem.new_from_search_result(search_result, query_name)
      add_entry_to_collection(item, query_name)
    end
  end

  def items
    @collection.values.sort
  end

  def item_urls
    @collection.keys.sort
  end

  def add_unique_item(item, inventory_id)
    if @collection.key?(item.url)
      ActivityLog.warn "Merging duplicate url: #{item.url}", inventory_id
    end
    @collection[item.url] = item    
  end

  def merge_collections!(query_collection)
    unless @source == :sheet && query_collection.source == :query
      raise "#merge_collections! must be called on an instance created from a spreadsheet and passed an instance created from a query"
    end
    query_collection.items.each do |query_collection_item|
      update_item(query_collection_item)
      (item_urls - query_collection.item_urls).each do |url|
        mark_as_missing(url)
      end
    end
  end

private
  def add_entry_to_collection(item, query_row_number)
    if @collection.key?(item.url)
      @collection[item.url].matching_queries <<  query_row_number.to_s
    else
      @collection[item.url] = item
    end
  end

  # updates this collection with data from an item from the query collection
  def update_item(query_collection_item)
    # get the corresponding item in this collection
    item = @collection[query_collection_item.url]
    if item.nil?
      # item doesn't exist, so just add it
      @collection[query_collection_item.url] = query_collection_item
    else
      item.update_from_other_item(query_collection_item)
    end
  end

  def mark_as_missing(url)
    @collection[url].mark_as_missing
  end
end
