class InventoryItemCollectionPresenter

  def initialize(inventory_item_collection)
    @iic = inventory_item_collection
  end

  def present_in_chunks(chunk_size, &block)
    start_index = 0
    while start_index < @iic.items.size
      items = @iic.items.slice(start_index, chunk_size)
      start_index += chunk_size
      chunk = present_items(items)
      yield(chunk)
    end
  end

private
  def present_items(items)
    rows = []
    items.each do |item|
      rows << InventoryItemPresenter.new(item).present
      end
    rows
  end
end
