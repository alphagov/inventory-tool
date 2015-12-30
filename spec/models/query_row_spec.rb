require 'rails_helper'


describe QueryRow do

  describe '#name' do
    it 'returns the description if present' do
      qr = QueryRow.new(['q="Early years"', 'Full early years'])
      expect(qr.name).to eq 'Full early years'
    end

    it 'returns the query if description is empty string' do
      qr = QueryRow.new(['q="Early years"', ''])
      expect(qr.name).to eq 'q="Early years"'
    end

    it 'returns the query if description is nil' do
      qr = QueryRow.new(['q="Early years"', nil])
      expect(qr.name).to eq 'q="Early years"'
    end
  end

  describe '#emtpy?' do
    it 'returns true if query is emtpy string' do
      qr = QueryRow.new(['', 'Some random text'])
      expect(qr).to be_empty
    end

    it 'returns true if query is nil' do
      qr = QueryRow.new([nil, 'Some random text'])
      expect(qr).to be_empty
    end

    it 'returns flase if query has content' do
      qr = QueryRow.new(['q="Early years"', nil])
      expect(qr).not_to be_empty
    end
  end
  
end
