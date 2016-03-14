require 'cgi'

module Rummager
  class SearchApiClient
    SEARCH_ENDPOINT = 'https://www.gov.uk/api/search.json'
    MAX_REQUIRED_RESULTS = 200_000

    attr_reader :search_url, :result_set

    def initialize(inventory_id, query)
      @query = URI.escape(URI.unescape(query))
      if @query =~ /&count=(\d+)/
        @num_required_results = $1.to_i
        @query.sub!(/&count=\d+/, '')
      else
        @num_required_results = MAX_REQUIRED_RESULTS
      end
      @query += "&fields=#{InventoryItem::ADDITIONAL_QUERY_FIELDS}"
      @inventory_id = inventory_id
    end

    def search
      count = [chunksize, @num_required_results].min
      response = get_response(0, count)
      @num_results_available = response['total']
      @result_set = response['results']

      while @result_set.size < @num_results_available && @result_set.size < @num_required_results
        start = @result_set.size
        count = @result_set.size + chunksize > @num_required_results ? @num_required_results - @result_set.size : chunksize
        response = get_response(start, count)
        @result_set += response['results']
      end
      @result_set
    end

    def self.num_docs_on_govuk
      response = JSON.parse(RestClient.get(SEARCH_ENDPOINT))
      response['total']
    end

  private

    def chunksize
      1000
    end

    def get_response(start, count)
      url = "#{SEARCH_ENDPOINT}?#{@query}&start=#{start}&count=#{count}"
      ActivityLog.debug "#{self.class}: Executing search: url: #{url}", @inventory_id
      begin
        json_response = RestClient.get("#{url}")
      rescue RestClient::UnprocessableEntity
        ActivityLog.error "Unprocessable Entity returned for query: #{url}", @inventory_id
        raise SearchApiClientError.new("Invalid query: #{url}")
      rescue => err
        message = "#{err.class}: #{err.message}, URL: #{url}"
        ActivityLog.error message, @inventory_id
        raise SearchApiClientError.new(message)
      end
      JSON.parse(json_response)
    end
  end
end
