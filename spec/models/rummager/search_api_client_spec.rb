require 'rails_helper'

module Rummager
  describe SearchApiClient do

    let(:base_url) { 'https://www.gov.uk/api/search.json'}
    let(:query) { "q=%22Early%20years%22" }
    let(:query_string) do
      base_url + 
      '?' + query +
      "&fields=link,title,description,public_timestamp," +
      "format,display_type,specialist_sectors,mainstream_browse_pages,organisations,policies,document_collections" +
      "&start=0" +
      "&count=0"
    end

    describe '.num_docs_on_gov_uk' do
      it 'queries the search api and returns the total number of documents on gov uk' do
        expect(RestClient).to receive(:get).with(base_url).and_return({ 'total' => 190_444}.to_json)
        expect(SearchApiClient.num_docs_on_govuk).to eq 190_444
      end
    end

    describe '#search' do
      context 'valid search params' do
        it 'gets the documents' do
          expect(RestClient).to receive(:get).with(url_with_count(query_string, 1000)).and_return(docs_response_json)

          result_set = SearchApiClient.new(999, query).search
          expect(result_set).to have(3).members
          expect(result_set[0]['title']).to eq 'Early years'
          expect(result_set[1]['title']).to eq 'Early years foundation stage'
          expect(result_set[2]['title']).to eq 'Early years qualifications finder'
        end
      end

      context 'other exception during search' do
        it 'raises a SearchApiClientError' do
          expect(RestClient).to receive(:get).and_raise(RuntimeError, "Dummy Error")
          expect{
            SearchApiClient.new(999, query).search
          }.to raise_error SearchApiClientError, "RuntimeError: Dummy Error, URL: #{url_with_count(query_string, 1000)}"
        end
      end
    end

    context 'result set larger than chunk size' do
      let(:client) { SearchApiClient.new(999, query) }

      context 'no count specified in query' do
        it 'should keep reading until the total number of documents has been read' do
          allow_any_instance_of(SearchApiClient).to receive(:chunksize).and_return(4)
          expect(RestClient).to receive(:get).with(url_with_count(query_string, 4)).and_return(long_docs_response_json(1, 4, 10))
          expect(RestClient).to receive(:get).with(url_with_start_and_count(query_string, 4, 4)).and_return(long_docs_response_json(5, 8, 10))
          expect(RestClient).to receive(:get).with(url_with_start_and_count(query_string, 8, 4)).and_return(long_docs_response_json(9, 10, 10))

          results = SearchApiClient.new(999, query).search
          expect(results.map{ |r| r['description']}).to eq(
            [ 
              'Description No. 1', 
              'Description No. 2', 
              'Description No. 3', 
              'Description No. 4', 
              'Description No. 5', 
              'Description No. 6', 
              'Description No. 7', 
              'Description No. 8', 
              'Description No. 9', 
              'Description No. 10',
            ])
        end
      end

      context 'count specified in query larger than one chunk but smaller than the total number of records' do
        it 'should only get the required number of records in chunks' do
          query = 'q="Early years"&count=7'

          allow_any_instance_of(SearchApiClient).to receive(:chunksize).and_return(4)
          expect(RestClient).to receive(:get).with(url_with_count(query_string, 4)).and_return(long_docs_response_json(1, 4, 10))
          expect(RestClient).to receive(:get).with(url_with_start_and_count(query_string, 4, 3)).and_return(long_docs_response_json(5, 7, 10))

          results = SearchApiClient.new(999, query).search
          expect(results.map{ |r| r['description']}).to eq(
            [ 
              'Description No. 1', 
              'Description No. 2', 
              'Description No. 3', 
              'Description No. 4', 
              'Description No. 5', 
              'Description No. 6', 
              'Description No. 7', 
            ])
        end
      end

      context 'count specifed in query larger than one chunk and larger than the total number of records' do
        it 'should get the total number of records in chunks' do
          query = 'q="Early years"&count=15'
          allow_any_instance_of(SearchApiClient).to receive(:chunksize).and_return(4)
          expect(RestClient).to receive(:get).with(url_with_count(query_string, 4)).and_return(long_docs_response_json(1, 4, 10))
          expect(RestClient).to receive(:get).with(url_with_start_and_count(query_string, 4, 4)).and_return(long_docs_response_json(5, 8, 10))
          expect(RestClient).to receive(:get).with(url_with_start_and_count(query_string, 8, 4)).and_return(long_docs_response_json(9, 10, 10))

          results = SearchApiClient.new(999, query).search
          expect(results.map{ |r| r['description']}).to eq(
            [ 
              'Description No. 1', 
              'Description No. 2', 
              'Description No. 3', 
              'Description No. 4', 
              'Description No. 5', 
              'Description No. 6', 
              'Description No. 7', 
              'Description No. 8', 
              'Description No. 9', 
              'Description No. 10',
            ])
        end
      end

      context 'count specified in query smaller than one chunk and the total number of records' do
        it 'should get just one chunk of the required number of records' do
          query = 'q="Early years"&count=5'
          allow_any_instance_of(SearchApiClient).to receive(:chunksize).and_return(8)
          expect(RestClient).to receive(:get).with(url_with_count(query_string, 5)).and_return(long_docs_response_json(1, 5, 5))

          results = SearchApiClient.new(999, query).search
          expect(results.map{ |r| r['description']}).to eq(
            [ 
              'Description No. 1', 
              'Description No. 2', 
              'Description No. 3', 
              'Description No. 4', 
              'Description No. 5', 
            ])
        end
      end
    end


    def url_with_start(url, start)
      url.sub(/&start=\d+/, "&start=#{start}")
    end

    def url_with_count(url, count)
      url.sub(/&count=\d+/, "&count=#{count}")
    end

    def url_with_start_and_count(url, start, count)
      url_with_count(url_with_start(url, start), count)
    end

    def long_docs_response_json(start, stop, total)
      result = []
      (start..stop).each do |i|
        hash = {'description' => "Description No. #{i}", 'link' => "/link_#{i}"}
        result << hash
      end
      response = {'results' => result, 'total' => total}
      response.to_json
    end


    def docs_response_json
      %q|
      {
        "results":[
          { 
            "description":"List of information about Early years.",
            "format":"specialist_sector",
            "link":"/topic/schools-colleges-childrens-services/early-years",
            "slug":"schools-colleges-childrens-services/early-years",
            "title":"Early years",
            "index":"mainstream",
            "es_score":0.006680511,
            "_id":"/topic/schools-colleges-childrens-services/early-years",
            "document_type":"edition"
          },
          {
            "description":"The early years foundation stage (EYFS) sets standards for the learning, development and care of children from birth to 5",
            "format":"answer",
            "link":"/early-years-foundation-stage",
            "organisations":[
              {
                "slug":"department-for-education",
                "title":"Department for Education",
                "acronym":"DfE",
                "organisation_state":"live",
                "link":"/government/organisations/department-for-education"
              }
            ],
            "public_timestamp":"2015-05-11T10:31:21+01:00",
            "title":"Early years foundation stage",
            "index":"mainstream",
            "es_score":0.0066603883,
            "_id":"/early-years-foundation-stage",
            "document_type":"edition"
          },
          {
            "description":"Find out if the qualifications held by you or staff working in an early years setting can be included in the staff to child ratio for the EYFS.",
            "display_type":"Detailed guide",
            "format":"detailed_guidance",
            "link":"/guidance/early-years-qualifications-finder",
            "organisations":[
              {
                "slug":"national-college-for-teaching-and-leadership",
                "title":"National College for Teaching and Leadership",
                "acronym":"NCTL",
                "organisation_state":"live",
                "link":"/government/organisations/national-college-for-teaching-and-leadership"
              }
            ],
            "public_timestamp":"2014-08-22T15:17:25.000+01:00",
            "title":"Early years qualifications finder",
            "topics":[
              {
                "title":"Children and young people",
                "slug":"children-and-young-people",
                "link":"/government/topics/children-and-young-people"
              }
            ],
            "index":"detailed",
            "es_score":0.004891127,
            "_id":"/guidance/early-years-qualifications-finder",
            "document_type":"edition"
          }
        ],
        "total":3,
        "start":0,
        "facets":{},
        "suggested_queries":[]
      }|
    end
  end
end






