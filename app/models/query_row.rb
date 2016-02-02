class QueryRow
  attr_reader :query

  def initialize(row)
    @query = row[0]
    @description = row[1]
  end

  def name
    @description.blank? ? @query : @description
  end

  def empty?
    @query.blank?
  end
end
