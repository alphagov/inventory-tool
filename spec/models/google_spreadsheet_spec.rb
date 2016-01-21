require 'rails_helper'
require 'support/inventory_item_spec_helper'

RSpec.describe GoogleSpreadsheet, type: :model do
  include InventoryItemSpecHelper

  let(:session)  { double('GoogleDriveSession')}
  let(:overview_ws) { double('GoogleDrive::Worksheet(Overview)', save: nil) }
  let(:documents_ws) { double('GoogleDrive::Worksheet(Documents)', num_rows: 85, num_cols: 18, save: nil ) }
  let(:queries_ws) { double('GoogleDrive::Worksheet(Queries)', num_rows: 2) }
  let(:spreadsheet) { double(GoogleDrive::Spreadsheet, 
    overview_worksheet: overview_ws, 
    documents_worksheet: documents_ws, 
    queries_worksheet: queries_ws) }
  let(:inventory) { double Inventory }

  
  before(:each) do
    allow(GoogleDrive).to receive(:saved_session).and_return(session)
    allow(spreadsheet).to receive(:worksheet_by_title).with('Overview').and_return(overview_ws)
    allow(spreadsheet).to receive(:worksheet_by_title).with('Documents').and_return(documents_ws)
    allow(spreadsheet).to receive(:worksheet_by_title).with('Queries').and_return(queries_ws)
    allow(spreadsheet).to receive(:key).and_return('my-key')
    allow(Inventory).to receive(:find_by!).with({key: 'my-key'}).and_return(inventory)
  end

  describe '.new' do
    it 'should raise NoMethodError when called from outside the class' do
      expect {
        GoogleSpreadsheet.new(title: 'my spreadsheet')
      }.to raise_error NoMethodError, "private method `new' called for GoogleSpreadsheet:Class"
    end

    it 'raises an ArgumentError if given invalid options' do
      expect{
        GoogleSpreadsheet.send(:new, name: 'xyz')
      }.to raise_error ArgumentError, 'Invalid options passed to GoogleSpreadsheet.new'
    end
  end

  describe '.find_by_key' do
    it 'finds an existing spreadsheet if given a key' do
      expect(session).to receive(:spreadsheet_by_key).with('my-key').and_return(spreadsheet)
      gs = GoogleSpreadsheet.find_by_key('my-key')
      expect(gs.instance_variable_get(:@spreadsheet)).to eq spreadsheet
    end
  end

  describe '.create_from_skeleton'do
    it 'duplicates the skeleton if given a title' do
      skeleton_spreadsheet = double(GoogleDrive::Spreadsheet)
      expect(session).to receive(:spreadsheet_by_key).with(GoogleSpreadsheet::SKELETON_KEY).and_return(skeleton_spreadsheet)
      expect(skeleton_spreadsheet).to receive(:copy).and_return(spreadsheet)
      expect(spreadsheet).to receive(:title=).with('my dupe')
      expect(spreadsheet).to receive(:acl).and_return(double(GoogleDrive::Acl, push: nil))
      allow(documents_ws).to receive(:num_rows).and_return(10)
      allow(documents_ws).to receive(:num_cols).and_return(18)
      allow(documents_ws).to receive(:update_cells)
      allow(overview_ws).to receive(:[]=)
      expect(overview_ws).to receive(:save)
      expect(documents_ws).to receive(:save)

      GoogleSpreadsheet.create_from_skeleton('my dupe')
    end
  end

  describe 'update' do
    it 'calls the InventoryItemCollectionPresenter to format data and update itself' do
      expect(session).to receive(:spreadsheet_by_key).with('my-dummy-key').and_return(spreadsheet)
      gs = GoogleSpreadsheet.find_by_key('my-dummy-key')

      iic = build_inventory_item_collection(:query, 3)
      expect(documents_ws).to receive(:num_rows).and_return(5)
      expect(documents_ws).to receive(:num_cols).and_return(18)
      expect(documents_ws).to receive(:update_cells).with(2, 1, Array.new(4, Array.new(18, nil)))
      expect(documents_ws).to receive(:max_rows=).with(5)

      # expect_any_instance_of(InventoryItemCollectionPresenter).to receive(:present).and_return('Dummy row data')
      
      # expect(documents_ws).to receive(:update_cells).with(2, 1, 'Dummy row data')
      expect(documents_ws).to receive(:update_cells).with(2, 1, chunk)
      expect(documents_ws).to receive(:save).exactly(3)

      gs.update(iic)
    end
  end

  describe 'calculate_overview_stats' do 
    it 'should gather the stats and put the results in the overview spreadsheet' do
      now = Time.now
        Timecop.freeze(now) do
        expect(session).to receive(:spreadsheet_by_key).with('my-dummy-key').and_return(spreadsheet)
        expect(Rummager::SearchApiClient).to receive(:num_docs_on_govuk).and_return(190_448)
        gs = GoogleSpreadsheet.find_by_key('my-dummy-key')

        expect(overview_ws).to receive(:[]=).with(1, 2, now.strftime('%Y-%m-%d %H:%M:%S'))
        expect(overview_ws).to receive(:[]=).with(2, 2, 1)
        expect(overview_ws).to receive(:[]=).with(3, 2, 84)
        expect(overview_ws).to receive(:[]=).with(4, 2, 190_448)

        gs.calculate_overview_stats
      end
    end
  end



  context 'spreadsheet access methods' do
    let(:gs) { GoogleSpreadsheet.find_by_key('my-key') }

    before(:each) do
      allow(session).to receive(:spreadsheet_by_key).with('my-key').and_return(spreadsheet)
      
    end

    describe '#delete' do
      it 'calls the delete method on the underlying spreadsheet object' do
        expect(spreadsheet).to receive(:delete)
        gs.delete!
      end
    end

    describe '#key' do
      it 'calls key on the underlying spreadsheet object' do
        expect(spreadsheet).to receive(:key).and_return('my-key')
        expect(gs.key).to eq 'my-key'
      end
    end

    describe '#documents' do
      it 'calls rows on the documents worksheet of the underlying spreadsheet and creates an InventoryItemCollection from the result' do
        worksheet = double 'Worksheet'
        rows = double 'Rows of a worksheet'
        expect(spreadsheet).to receive(:worksheet_by_title).with('Documents').and_return(worksheet)
        expect(worksheet).to receive(:rows).and_return(rows)
        expect(InventoryItemCollection).to receive(:new_from_spreadsheet).with(999, rows)
        gs.documents(999)
      end
    end

    describe '#query_rows' do
      it 'calls rows on the queries worksheet of the underlying spreadsheet and returns the first column of each row' do
        worksheet = double 'Worksheet'
        rows = [ ['aaa', 'bbb'], ['AAAA', 'BBBB', 'CCCC'], ['1234'] ]
        allow(queries_ws).to receive(:rows).with(1).and_return(rows)
        expect(gs.query_rows.size).to eq 3
        expect(gs.query_rows.map(&:class).uniq).to eq [QueryRow]
        expect(gs.query_rows.map(&:query)).to eq(%w{ aaa AAAA 1234})
        expect(gs.query_rows.map(&:name)).to eq(%w{ bbb BBBB 1234})
      end
    end

    describe '#inventory' do
      let(:inventory) { create :inventory, key: 'my-key' }
      it 'should get the inventory if it is not cached' do
        gs = GoogleSpreadsheet.find_by_key(inventory.key)
        expect(gs.instance_variable_get(:@inventory)).to be_nil
        expect(gs.inventory).to eq inventory
      end
      
      it 'should return the cached value for inventory if not nil' do
      gs = GoogleSpreadsheet.find_by_key(inventory.key)
      gs.instance_variable_set(:@inventory, 'my-inventory')
      expect(Inventory).not_to receive(:find_by!).with({key: 'my-key'})
      expect(gs.inventory).to eq 'my-inventory'
      end
    end
  end

  def chunk
    [
      [
        "Dummy Item no. 0", 
        "https://www.gov.uk/dummy/0", 
        nil, 
        "2015-01-01", 
        "2015-12-25 08:36", 
        "DfE; HMRC; MOJ", 
        "Speech", 
        "Detailed guide", 
        "childcare-and-early-education; special-educational-needs-and-disability-send", 
        "first topic; last topic; middle topic", 
        "births-deaths-marriages/child-adoption; education/school-life", 
        "Early years and childcare inspections: resources for inspectors and other organisations; Ofsted inspections of registered childcare providers; Ofsted's compliance, investigation and enforcement handbooks", 
        "", 
        "", 
        "2; 3", 
        nil,
        "this is the recommendation that we have come up with", 
        "/early-years/childcare", 
        "These are notes for this item"
      ], 
      [
        "Dummy Item no. 1", 
        "https://www.gov.uk/dummy/1", 
        nil, 
        "2015-01-01", 
        "2015-12-25 08:36", 
        "DfE; HMRC; MOJ", 
        "Speech", 
        "Detailed guide", 
        "childcare-and-early-education; special-educational-needs-and-disability-send", 
        "first topic; last topic; middle topic", 
        "births-deaths-marriages/child-adoption; education/school-life", 
        "Early years and childcare inspections: resources for inspectors and other organisations; Ofsted inspections of registered childcare providers; Ofsted's compliance, investigation and enforcement handbooks",
        "", 
        "", 
        "2; 3",
        nil,
        "this is the recommendation that we have come up with", 
        "/early-years/childcare", 
        "These are notes for this item"
      ], 
      [
        "Dummy Item no. 2", "https://www.gov.uk/dummy/2", 
        nil, 
        "2015-01-01", 
        "2015-12-25 08:36", 
        "DfE; HMRC; MOJ", 
        "Speech", 
        "Detailed guide", 
        "childcare-and-early-education; special-educational-needs-and-disability-send", 
        "first topic; last topic; middle topic", 
        "births-deaths-marriages/child-adoption; education/school-life", 
        "Early years and childcare inspections: resources for inspectors and other organisations; Ofsted inspections of registered childcare providers; Ofsted's compliance, investigation and enforcement handbooks", 
        "", 
        "", 
        "2; 3", 
        nil,
        "this is the recommendation that we have come up with", 
        "/early-years/childcare", 
        "These are notes for this item"
      ]
    ]
  end
end

























