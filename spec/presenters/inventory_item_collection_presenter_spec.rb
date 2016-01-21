require 'rails_helper'
require 'support/inventory_item_spec_helper'

describe InventoryItemCollectionPresenter do 
  include InventoryItemSpecHelper

  describe '#present_in_chunks' do
    let(:result_sets) { Array.new }
    let(:iic) { build_inventory_item_collection(:sheet, 10) }
    let(:presenter) { InventoryItemCollectionPresenter.new(iic) }

    before(:each) do
      presenter.present_in_chunks(3) do |chunk|
        result_sets << chunk
      end
    end

    it 'creates a result set of 4 chunks containing 3, 3, 3, and 1 rows' do
      expect(result_sets.size).to eq 4
      expect(result_sets.map(&:size)).to eq([ 3, 3, 3, 1 ])
    end

    it 'returns the first chunk of 3 rows of 18 elements' do
      chunk = result_sets.first
      expect(chunk).to be_instance_of(Array)
      expect(chunk.map(&:first)).to eq([ 'Dummy Item no. 0', 'Dummy Item no. 1', 'Dummy Item no. 2'])
      row = chunk.first
      expect(row.size).to eq 19
    end

    it 'returns the last chunk of an array of just one row' do
      chunk = result_sets.last
      expect(chunk).to be_instance_of(Array)
      row = chunk.last
      expect(row.first).to eq 'Dummy Item no. 9'
      expect(row.size).to eq 19
    end

  end
end
