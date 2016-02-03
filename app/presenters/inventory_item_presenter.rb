class InventoryItemPresenter
  def initialize(inventory_item)
    @item = inventory_item
  end

  def present
    InventoryItem::FIELD_POSITIONS.map do |field|
      present_field(field)
    end
  end

private
  def present_field(field)
    specialized_method = presenter_method_for(field)
    respond_to?(specialized_method, true) ? send(specialized_method) : @item.send(field)
  end

  def presenter_method_for(field)
    "present_#{field}".to_sym
  end

  def present_url
    "#{InventoryItem::GOVUK_BASE_URL}#{@item.url}"
  end

  def present_last_updated
    @item.last_updated.respond_to?(:strftime) ? @item.last_updated.strftime('%Y-%m-%d %H:%M') : nil
  end

  def present_topics
    present_array(@item.topics)
  end

  def present_mainstream_browse_pages
    present_array(@item.mainstream_browse_pages)
  end

  def present_matching_queries
    present_array(@item.matching_queries)
  end

  def present_organisations
    present_array(@item.organisations)
  end

  def present_policies
    present_array(@item.policies)
  end

  def present_document_collections
    present_array(@item.document_collections)
  end

  def present_is_withdrawn
    present_bool(@item.is_withdrawn)
  end

  def present_is_historic
    present_bool(@item.is_historic)
  end

  def present_first_published_date
    @item.first_published_date.respond_to?(:strftime) ? @item.first_published_date.strftime('%Y-%m-%d') : ''
  end

  def present_array(array)
    array.blank? ? '' : array.sort.join(InventoryItem::ARRAY_SEPARATOR)
  end

  def present_bool(value)
    value ? 'Yes' : 'No'
  end
end
