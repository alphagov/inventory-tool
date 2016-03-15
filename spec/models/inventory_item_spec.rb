require 'rails_helper'
require 'support/inventory_item_spec_helper'

describe InventoryItem do
  include InventoryItemSpecHelper

  describe '.new_from_spreadsheet_row' do
    it 'assigns the fields from the row to the items attributes' do
      row = [
        "Benefits overview",
        "http://www.gov.uk/tax/benfits",
        "This is a long-winded description",
        "30/12/2015 16:17:45",
        "12/01/2016 23:33:22",
        "HMRC; DHSS",
        "detailed_guide_format",
        "Detailed guide",
        "tax topic; this topic; that topic",
        "Benefits mainstream browse page; Aardvark mainstream browse page",
        "My Policy; His Policy",
        "Housing; Taxations; Other Stuff",
        "NO",
        "NO",
        "2; 4",
        "relevance",
        "recs",
        "combines",
        "Notes notes and more notes"
      ]
      item = InventoryItem.new_from_spreadsheet_row(999, row)
      expect(item.title).to eq "Benefits overview"
      expect(item.url).to eq "http://www.gov.uk/tax/benfits"
      expect(item.description).to eq "This is a long-winded description"
      expect(item.first_published_date).to eq "30/12/2015 16:17:45"
      expect(item.last_updated).to eq "12/01/2016 23:33:22"
      expect(item.organisations).to eq %w{HMRC DHSS}
      expect(item.format).to eq "detailed_guide_format"
      expect(item.display_type).to eq "Detailed guide"
      expect(item.policies).to eq ['My Policy', 'His Policy']
      expect(item.topics).to eq ['tax topic', 'this topic', 'that topic']
      expect(item.mainstream_browse_pages).to eq ['Benefits mainstream browse page', 'Aardvark mainstream browse page']
      expect(item.document_collections).to eq ['Housing', 'Taxations', 'Other Stuff']
      expect(item.is_withdrawn).to be false
      expect(item.is_historic).to be false
      expect(item.matching_queries).to eq %w{ 2 4 }
      expect(item.recommendation).to eq "recs"
      expect(item.redirect_combine_url).to eq "combines"
      expect(item.notes).to eq "Notes notes and more notes"
    end
  end

  describe '.new_from_search_result' do
    context 'population of fields which are missing from the search result' do
      let(:fields_blank_when_missing) { [:relevance, :redirect_combine_url, :notes, :recommendation] }
      let(:fields_that_must_be_present) { [:url, :matching_queries] }
      let(:fields_that_should_be_an_emtpy_array_when_missing) { InventoryItem::ARRAY_FIELDS - [:matching_queries] }
      let(:fields_that_must_be_false_when_missing) { [:is_withdrawn, :is_historic] }
      let(:fields_that_must_be_nil_when_missing) { [:last_updated, :description] }
      let(:fields_that_must_be_none_when_missing) { [:display_type] }
      let(:fields_unknown_when_missing) {
        InventoryItem::FIELD_POSITIONS -
          fields_blank_when_missing -
          fields_that_must_be_present -
          fields_that_must_be_false_when_missing -
          fields_that_must_be_none_when_missing -
          InventoryItem::ARRAY_FIELDS -
          fields_that_must_be_nil_when_missing
      }

      let(:item) { InventoryItem.new_from_search_result({'link' => '/abc'}, 4) }

      it 'populates fields with None' do
        expect(item.display_type).to eq 'None'
      end

      it 'populates fields with Unknown' do
        fields_unknown_when_missing.each do |fieldname|
          message = "Expected @#{fieldname} to be 'Unknown', was '#{item.send(fieldname)}'"
          expect(item.send(fieldname)).to eq('Unknown'), message
        end
      end

      it 'populates fields with empty string' do
        fields_blank_when_missing.each do |fieldname|
          message = "Expected @#{fieldname} to be blank, was '#{item.send(fieldname).inspect}'"
          expect(item.send(fieldname)).to eq(''), message
        end
      end

      it 'populates missing array fields with an empty array' do
        fields_that_should_be_an_emtpy_array_when_missing.each do |fieldname|
          message = "Expected @#{fieldname} to be an emtpy array, was #{item.send(fieldname).inspect}"
          expect(item.send(fieldname)).to eq([]), message
        end
      end

      it 'populates missings nil fields with nil' do
        fields_that_must_be_nil_when_missing.each do |fieldname|
          message = "Expected @#{fieldname} to be nil, was #{item.send(fieldname).inspect}"
          expect(item.send(fieldname)).to be_nil, message
        end
      end
    end

    context 'population of fields which are present in the result set' do
      require_relative '../data/search_api_client_results'
      let(:search_result) {
        dummy_search_api_results
        { 'link' => '/early-education',
          'title' => 'Early years education',
          'description' => "A guide to eduction for the under 8s",
          'format' => 'detailed_guidance_format',
          'specialist_sectors' => [
            {
              'link' => '/aardvark-sexing-in-the-early-years',
              'title' => 'aardvark sexing',
              'slug' => 'aardvark-sexing-in-the-early-years',
            },
            {
              'link' => '/zebra-preservation',
              'title' => 'Zebra preservation',
              'slug' => 'zebra-preservation',
            },
            {
              'link' => '/hippo-management',
              'title' => 'hippo management',
              'slug' => 'hippo management',
            },
          ],
          'policies' => [
            'special-educational-needs-and-disability-send',
            'looked-after-children-and-adoption',
            'childcare-and-early-education',
          ],
          'organisations' => [
            {
              'title' => 'Ministry of Justice',
              'acronym' => 'MOJ',
              'link' => '/ministry-of-justice',
            },
            {
              'title' => 'Department of Education',
              'acronym' => 'DoE',
              'link' => '/doe',
            },
          ],
          'document_collections' => [
            {
              'title' => "Early learning and childcare: guidance for providers",
              'slug' => "early-learning-and-childcare-guidance-for-early-years-providers",
              'link' => "/government/collections/early-learning-and-childcare-guidance-for-early-years-providers"
            },
            {
              'title' => "Early learning accreditation",
              'slug' => "early-learning-accrediation",
              'link' => "/government/collections/early-learning-accrediation"
            },
          ],
          'public_timestamp' => '2016-01-04T11:17:25.000+00:00',
          'index' => 'speech',
          'es_score' =>  0.0058470573,
          '_id' => '/guidance/early-years-qualifications-finder',
          'document_type' => 'edition'
        }
      }
      let(:item) { InventoryItem.new_from_search_result(search_result, 2)}

      it 'populates the url from the links field' do
        expect(item.url).to eq '/early-education'
      end

      it 'populates the title field' do
        expect(item.title).to eq 'Early years education'
      end

      it 'populates the topics fields with capitalized titles in alphabetic order' do
        expect(item.topics).to eq(['Aardvark sexing', 'Hippo management', 'Zebra preservation'])
      end

      it 'populates the organisations fields with capitalized acronyms in alphabetic order' do
        expect(item.organisations).to eq %w{ DoE MOJ }
      end

      it 'populates last updated from the public timestamp' do
        expect(item.last_updated).to eq(Time.new(2016, 1, 4, 11, 17, 25, 0))
      end

      it 'populates policies' do
        expect(item.policies).to eq(%w{
          childcare-and-early-education
          looked-after-children-and-adoption
          special-educational-needs-and-disability-send }
                                   )
      end

      it 'populates document collections with titles in alphabetic order' do
        expect(item.document_collections).to eq(['Early learning accreditation', 'Early learning and childcare: guidance for providers'])
      end

      it 'humanizes the format' do
        expect(item.format).to eq 'Detailed guidance format'
      end
    end
  end

  describe '.new' do
    it 'raises an error when called' do
      expect {
        InventoryItem.new
      }.to raise_error NoMethodError, "private method `new' called for InventoryItem:Class"
    end
  end

  context 'sorting' do
    it 'should sort by url' do
      item_1 = InventoryItem.send(:new, url: '/zebras', title: 'aardvarks and zebras')
      item_2 = InventoryItem.send(:new, url: '/aardvarks', title: 'aardvarks only')
      item_3 = InventoryItem.send(:new, url: '/hippos', title: 'hippos')

      array = [item_1, item_2, item_3].sort
      expect(array.map(&:url)).to eq(%w{ /aardvarks /hippos /zebras })
    end
  end

  describe '#mark_as_missing' do
    it 'should insert the not returned message if not in the notes' do
      Timecop.freeze(Time.new(2016, 1, 6, 14, 28, 22, 0)) do
        item = build_inventory_item(notes: "these are the pre-existing notes\nover several lines")
        item.mark_as_missing
        expect(item.notes).to eq("Not returned from search as of 2016-01-06 14:28; these are the pre-existing notes\nover several lines")
      end
    end

    it 'should insert in the not returned message if already in the notes' do
      Timecop.freeze(Time.new(2016, 1, 6, 14, 28, 22, 0)) do
        item = build_inventory_item(notes: "Not returned from search as of 2015-12-20 13:02; these are the pre-existing notes\nover several lines")
        item.mark_as_missing
        expect(item.notes).to eq("Not returned from search as of 2015-12-20 13:02; these are the pre-existing notes\nover several lines")
      end
    end

    it 'should insert the not_returned message if the notes are empty' do
      Timecop.freeze(Time.new(2016, 1, 6, 14, 28, 22, 0)) do
        item = build_inventory_item(notes: nil)
        item.mark_as_missing
        expect(item.notes).to eq("Not returned from search as of 2016-01-06 14:28; ")
      end
    end
  end

  describe '#extract_from_array of hashes(private_method)' do
    let(:doc) do
      {
        'element' => [
          { 'name' => 'HMRC', 'slug' => '/hmrc', 'title' => 'Taxation', 'minister' => 'George Osborne' },
          { 'name' => 'Dfe', 'slug' => '/dfe', 'title' => 'Education' },
          { 'name' => 'MOJ', 'slug' => '/moj', 'title' => 'Law'},
        ]
      }
    end
    let(:item) { InventoryItem.send(:new) }

    it 'should extract a list of values for the given field' do
      expect(item.send(:extract_from_array_of_hashes, doc, 'element', 'name')).to eq %w{ Dfe HMRC MOJ }
    end

    it 'should substitue title if specified field is not present in hash' do
      expect(item.send(:extract_from_array_of_hashes, doc, 'element', 'minister')).to eq(['Education', 'George Osborne', 'Law'])
    end

    it 'should use the specified fallback field' do
      expect(item.send(:extract_from_array_of_hashes, doc, 'element', 'minister', 'slug')).to eq(['/dfe', '/moj', 'George Osborne'])
    end

    it 'should insert error message if no such field found' do
      result = item.send(:extract_from_array_of_hashes, doc, 'element', 'location', 'minister')
      expect(result).to eq(["George Osborne", "No location or minister in search results", "No location or minister in search results"])
    end
  end

  context 'updating from other InventoryItem' do
    let(:now) { Time.now }
    let(:item) { build_inventory_item }
    let(:other_item) do
      build_inventory_item(
        title: 'Updated title',
        last_updated: now,
        format: 'Press Release',
        display_type: 'Guidance',
        topics: ['added topic no 1', 'another added topic'],
        mainstream_browse_pages: ['my_new_browse_page'],
        organisations: %w{ HMRC DfE MOJ },
        policies: [],
        document_collections: ['Ofsted inspections of registered childcare providers'],
        matching_queries: [2, 4, 5],
        is_withdrawn: true,
        is_historic: true,
        first_published_date: Date.new(2014, 1, 1),
        recommendation: nil,
        redirect_combine_url: nil,
        notes: nil)
    end

    before(:each) { item.update_from_other_item(other_item) }

    it 'does not update url' do
      expect(item.url).to eq '/my_url'
    end

    it 'updates all the updateable fields with values from the other item' do
      expect(item.title).to eq 'Updated title'
      expect(item.last_updated).to eq now
      expect(item.format).to eq 'Press Release'
      expect(item.display_type).to eq 'Guidance'
      expect(item.is_withdrawn).to be true
      expect(item.is_historic).to be true
      expect(item.first_published_date).to eq Date.new(2014, 1, 1)
    end

    it 'merges the mergeable fields' do
      expect(item.topics).to eq(['added topic no 1', 'another added topic', 'first topic', 'last topic', 'middle topic'])
      expect(item.mainstream_browse_pages).to eq(%w{births-deaths-marriages/child-adoption education/school-life my_new_browse_page })
      expect(item.organisations).to eq(%w{ DfE HMRC MOJ })
      expect(item.policies).to eq(%w{ childcare-and-early-education  special-educational-needs-and-disability-send })
      expect(item.document_collections).to eq([
        "Early years and childcare inspections: resources for inspectors and other organisations",
        "Ofsted inspections of registered childcare providers",
        "Ofsted's compliance, investigation and enforcement handbooks",
      ])
      expect(item.matching_queries).to eq([2, 3, 4, 5])
    end

    it 'removes the not returned message if there' do
      item.notes = "These are notes; Not returned from search as of #{Time.now.strftime('%Y-%m-%d %H:%M')}; More notes"
      item.update_from_other_item(other_item)
      expect(item.notes).to eq "These are notes; More notes"
    end

    it 'leaves notes unchanged if they dont contain a not returned phrase' do
      expect(item.notes).to eq "These are notes for this item"
    end
  end
end
