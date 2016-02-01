require 'rails_helper'
require 'support/inventory_item_spec_helper'

describe InventoryItemPresenter do
  include InventoryItemSpecHelper

  let(:presenter) { InventoryItemPresenter.new(item) }
  let(:row) { presenter.present }

  def index_for(field)
    InventoryItem::FIELD_POSITIONS.index(field)
  end

  describe '#present' do
    context 'fully populated item' do
      let(:item) { build_inventory_item }

      it 'should return standard array of fields' do
        expect(row).to be_instance_of(Array)
        expect(row.size).to eq 19
      end

      it 'presents values correctly from a fully populated item' do
        expect(row[index_for(:url)]).to eq 'https://www.gov.uk/my_url'
        expect(row[index_for(:title)]).to eq 'My Dummy Inventory Item'
        expect(row[index_for(:last_updated)]).to eq '2015-12-25 08:36'
        expect(row[index_for(:format)]).to eq 'Speech'
        expect(row[index_for(:display_type)]).to eq 'Detailed guide'
        expect(row[index_for(:topics)]).to eq 'first topic; last topic; middle topic'
        expect(row[index_for(:mainstream_browse_pages)]).to eq 'births-deaths-marriages/child-adoption; education/school-life'
        expect(row[index_for(:organisations)]).to eq 'DfE; HMRC; MOJ'
        expect(row[index_for(:policies)]).to eq 'childcare-and-early-education; special-educational-needs-and-disability-send'
        expect(row[index_for(:document_collections)]).to eq "Early years and childcare inspections: resources for inspectors and other organisations; " +
          "Ofsted inspections of registered childcare providers; " +
          "Ofsted's compliance, investigation and enforcement handbooks"
        expect(row[index_for(:is_withdrawn)]).to eq ''
        expect(row[index_for(:in_history_mode)]).to eq ''
        expect(row[index_for(:first_published_date)]).to eq '2015-01-01'
        expect(row[index_for(:matching_queries)]).to eq '2; 3'
        expect(row[index_for(:recommendation)]).to eq 'this is the recommendation that we have come up with'
        expect(row[index_for(:redirect_combine_url)]).to eq '/early-years/childcare'
        expect(row[index_for(:notes)]).to eq 'These are notes for this item'
      end
    end

    context 'empty_item' do
      let(:item) { build_blank_inventory_item(url: '/my-blank-item') }

      it 'should return standard array of fields' do
        expect(row).to be_instance_of(Array)
        expect(row.size).to eq 19
      end

      it 'presents values correctly from a fully populated item' do
        expect(row[index_for(:url)]).to eq 'https://www.gov.uk/my-blank-item'
        expect(row[index_for(:title)]).to be_blank
        expect(row[index_for(:last_updated)]).to be_blank
        expect(row[index_for(:format)]).to be_blank
        expect(row[index_for(:display_type)]).to be_blank
        expect(row[index_for(:topics)]).to be_blank
        expect(row[index_for(:mainstream_browse_pages)]).to be_blank
        expect(row[index_for(:organisations)]).to be_blank
        expect(row[index_for(:policies)]).to be_blank
        expect(row[index_for(:document_collections)]).to be_blank
        expect(row[index_for(:is_withdrawn)]).to eq ''
        expect(row[index_for(:in_history_mode)]).to eq ''
        expect(row[index_for(:first_published_date)]).to be_blank
        expect(row[index_for(:matching_queries)]).to be_blank
        expect(row[index_for(:recommendation)]).to be_blank
        expect(row[index_for(:redirect_combine_url)]).to be_blank
        expect(row[index_for(:notes)]).to be_blank
      end
    end

    context 'true booleans' do
      let(:item) { build_inventory_item(is_withdrawn: true, in_history_mode: true) }

      it 'should translate true to YES' do
        expect(row[index_for(:is_withdrawn)]).to eq 'Withdrawn'
        expect(row[index_for(:in_history_mode)]).to eq 'History mode'
      end
    end
  end
end
