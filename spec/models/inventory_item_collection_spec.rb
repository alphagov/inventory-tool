require 'rails_helper'
require 'support/inventory_item_spec_helper'

describe InventoryItemCollection do
  include InventoryItemSpecHelper

  let(:inventory) { create :inventory }

  let(:rows) {
    [
      [
        "Benefits overview",
        "https://www.gov.uk/tax/benfits",
        "This is a long-winded description",
        "30/12/2015 16:17:45",
        "12/01/2016 23:33:22",
        "HMRC; DHSS",
        "answer",
        "Detailed guide",
        "tax topic; this topic; that topic",
        "Benefits mainstream browse page; Aardvark mainstream browse page",
        "My Policy; His Policy",
        "Housing; Taxations; Other Stuff",
        "NO",
        "NO",
        "bar; foo",
        "recs",
        "combines",
        "Notes notes and more notes"
      ],
      [
        "Benefits overview",
        "https://www.gov.uk/tax/childcare",
        "This is a long-winded description",
        "30/12/2015 16:17:45",
        "12/01/2016 23:33:22",
        "HMRC; DHSS",
        "answer",
        "Detailed guide",
        "tax topic; this topic; that topic",
        "Benefits mainstream browse page; Aardvark mainstream browse page",
        "My Policy; His Policy",
        "Housing; Taxations; Other Stuff",
        "NO",
        "NO",
        "bar; foo",
        "recs",
        "combines",
        "Notes notes and more notes"
      ],
    ]
  }

  let(:iic) { InventoryItemCollection.new_from_spreadsheet(inventory, rows) }

  describe '.new' do
    it 'raises an error if called from outside the class' do
      expect{
        InventoryItemCollection.new(:query)
      }.to raise_error NoMethodError, "private method `new' called for InventoryItemCollection:Class"
    end

    it 'should raise an error if the source is invalid' do
      expect{
        InventoryItemCollection.send(:new, :xxx)
      }.to raise_error ArgumentError, 'Source must be :query or :sheet'
    end
  end

  describe '.new_from_spreadsheet' do

    it 'has the same number of InventoryItems as rows' do
      expect(iic.size).to eq rows.size
    end

    it 'is a collection of InventoryItems keyed by url' do
      expect(iic.items.map(&:class)).to eq([InventoryItem, InventoryItem])
    end

    it 'populates the fields in the inventory items' do
      expect(iic.items[0].url).to eq '/tax/benfits'
      expect(iic.items[1].topics).to eq(["tax topic", "this topic", "that topic"])
    end
  end

  describe '#items' do
    it 'returns an array of InventoryItems sorted by url' do
      iic = InventoryItemCollection.send(:new, :sheet)
      iic.collection['/tax/benefits'] = InventoryItem.send(:new, {url: '/tax/benefits'})
      iic.collection['/childcare'] = InventoryItem.send(:new, {url: '/childcare'})
      iic.collection['/aardvark/maintenance'] = InventoryItem.send(:new, {url: '/aardvark/maintenance'})
      expect(iic.items.map(&:url)).to eq( %w{ /aardvark/maintenance /childcare /tax/benefits })
    end
  end

  describe '.new_from_search_queries' do
    let(:query_row_1) { QueryRow.new(['q="Early years"', 'Early years']) }
    let(:query_row_2) { QueryRow.new(['q="Late years"', 'Late years']) }

    it 'should call Rummager::SearchApiClient and add results for every query' do
      iic = double InventoryItemCollection
      client1 = double Rummager::SearchApiClient
      client2 = double Rummager::SearchApiClient
      result_set_1 = [ 'result_set_1' ]
      result_set_2 = [ 'result_set_2' ]
      expect(InventoryItemCollection).to receive(:new).with(:query).and_return(iic)
      expect(Rummager::SearchApiClient).to receive(:new).with(inventory.id, query_row_1.query).and_return(client1)
      expect(Rummager::SearchApiClient).to receive(:new).with(inventory.id, query_row_2.query).and_return(client2)
      expect(client1).to receive(:search).and_return(result_set_1)
      expect(client2).to receive(:search).and_return(result_set_2)
      expect(iic).to receive(:add_search_results).with(result_set_1, query_row_1.name)
      expect(iic).to receive(:add_search_results).with(result_set_2, query_row_2.name)

      InventoryItemCollection.new_from_search_queries(inventory, [query_row_1, query_row_2])
    end

    it 'should update matched queries when two queries produce the same document' do
      result_1 = [{'link' => '/early-years-accreditation-process'},{'link' => '/early-years-learning-centres'}]
      result_2 = [{'link' => '/early-years-accreditation-process'},{'link' => '/adult-education'}]
      client1 = double Rummager::SearchApiClient
      client2 = double Rummager::SearchApiClient
      expect(Rummager::SearchApiClient).to receive(:new).with(inventory.id, query_row_1.query).and_return(client1)
      expect(Rummager::SearchApiClient).to receive(:new).with(inventory.id, query_row_2.query).and_return(client2)
      expect(client1).to receive(:search).and_return(result_1)
      expect(client2).to receive(:search).and_return(result_2)
      iic = InventoryItemCollection.new_from_search_queries(inventory, [query_row_1, query_row_2])
      expect(iic.items.map(&:url)).to eq(%w{ /adult-education /early-years-accreditation-process /early-years-learning-centres})
      expect(iic.items.map(&:matching_queries)).to eq ([["Late years"], ["Early years", "Late years"], ["Early years"]])
    end
  end

  describe '#merge_collections!' do
    it 'should raise if called on an InventoryItemCollection which was created by query' do
      iic = InventoryItemCollection.send(:new, :query)
      other_iic = InventoryItemCollection.send(:new, :sheet)
      expect {
        iic.merge_collections!(other_iic)
      }.to raise_error RuntimeError, "#merge_collections! must be called on an instance created from a spreadsheet and passed an instance created from a query"
    end

    context 'updating a collection instantiated from a spreadsheet with a collection instantiated from a query' do
      let(:item_1) { InventoryItem.send(:new, url: '/abc/def/1') }
      let(:item_1_dupe) { InventoryItem.send(:new, url: '/abc/def/1') }
      let(:item_2) { InventoryItem.send(:new, url: '/abc/xyz/2') }
      let(:item_3) { InventoryItem.send(:new, url: '/abc/xyz/3') }
      let(:google_iic) {
        iic = InventoryItemCollection.send(:new, :sheet)
        iic.collection['/abc/def/1'] = item_1
        iic.collection['/abc/xyz/2'] = item_2
        iic
      }

      it 'should call update on items that appear in the query collection' do
        query_iic = InventoryItemCollection.send(:new, :query)
        query_iic.collection[item_1_dupe.url] = item_1_dupe

        expect(google_iic.collection[item_1.url]).to receive(:update_from_other_item).with(item_1_dupe)
        google_iic.merge_collections!(query_iic)
        expect(google_iic.items.size).to eq 2
      end

      it 'should add the item from the query collection if it doesnt exist in the sheet collection' do
        query_iic = InventoryItemCollection.send(:new, :query)
        query_iic.collection[item_3.url] = item_3

        google_iic.merge_collections!(query_iic)
        expect(google_iic.collection).to have_key(item_3.url)
        expect(google_iic.items.size).to eq 3
        expect(google_iic.items).to include(item_3)
      end

      it 'should mark items in the sheet collection that are not int he query collection as missing' do
        query_iic = InventoryItemCollection.send(:new, :query)
        query_iic.collection[item_3.url] = item_3

        expect(item_2).to receive(:mark_as_missing)
        google_iic.merge_collections!(query_iic)
      end

      describe 'overwriting mergeable fields for an item that is still present in the inventory' do
        context "with an empty field in the new collection" do
          it "clears the value" do
            query_iic = InventoryItemCollection.send(:new, :query)

            iic.merge_collections!(query_iic)

            iic.items.each do |inventory_item|
               expect(inventory_item.matching_queries).to eq([])
            end
          end
        end
        
        context "with a changed field in the new collection" do
          let (:changed_item) {InventoryItem.send(:new, {url: "/tax/childcare"})}

          it "replaces the value" do
            expect(iic.collection[changed_item.url].matching_queries).to eq(['bar', 'foo'])

            changed_item.matching_queries = ['foo', 'baz']
            query_iic = InventoryItemCollection.send(:new, :query)
            query_iic.collection[changed_item.url] = changed_item
            iic.merge_collections!(query_iic)

            expect(iic.collection[changed_item.url].matching_queries).to eq(['baz', 'foo'])
          end
        end
      end
    end
  end
end
