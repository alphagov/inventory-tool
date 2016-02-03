module InventoryItemSpecHelper
  def build_inventory_item(options = {})
    default_options = {
      url: '/my_url',
      title: 'My Dummy Inventory Item',
      last_updated: Time.new(2015, 12, 25, 8, 36, 48, 0),
      format: 'Speech',
      display_type: 'Detailed guide',
      topics: ['first topic', 'middle topic', 'last topic'],
      mainstream_browse_pages: %w{births-deaths-marriages/child-adoption education/school-life },
      organisations: %w{ HMRC DfE MOJ },
      policies: %w{ special-educational-needs-and-disability-send childcare-and-early-education },
      document_collections: [
        "Early years and childcare inspections: resources for inspectors and other organisations",
        "Ofsted's compliance, investigation and enforcement handbooks",
        "Ofsted inspections of registered childcare providers",
      ],
      is_withdrawn: false,
      is_historic: false,
      first_published_date: Date.new(2015, 1, 1),
      matching_queries: [2, 3],
      recommendation: "this is the recommendation that we have come up with",
      redirect_combine_url: "/early-years/childcare",
      notes: "These are notes for this item",
    }
    params = default_options.update(options)
    InventoryItem.send(:new, params)
  end

  def build_blank_inventory_item(options = {})
    InventoryItem.send(:new, options)
  end

  def build_inventory_item_collection(source, number_of_items)
    iic = InventoryItemCollection.send(:new, source)
    number_of_items.times do |i|
      item = build_inventory_item(url: "/dummy/#{i}", title: "Dummy Item no. #{i}")
      iic.add_unique_item(item, 999)
    end
    iic
  end
end
