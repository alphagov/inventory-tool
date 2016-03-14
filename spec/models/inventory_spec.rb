require 'rails_helper'

RSpec.describe Inventory, type: :model do
  context 'validations' do
    it 'rejects an empty name' do
      inventory = build :inventory, name: nil
      expect(inventory.valid?).to be false
      expect(inventory.errors[:name]).to eq(["You must specify a name"])
    end

    it 'rejects a duplicate name' do
      inventory_1 = create :inventory, name: 'xxxx'
      inventory_2 = build :inventory, name: 'xxxx'
      expect(inventory_2.valid?).to be false
      expect(inventory_2.errors[:name]).to eq(["There is already an inventory spreadsheet with the same name"])
    end

    it 'rejects and emtpy key' do
      inventory = build :inventory, key: nil
      expect(inventory.valid?).to be false
      expect(inventory.errors[:key]).to eq(["System Error: No key has been specified"])
    end

    it 'rejects the creation of a second skeleton' do
      skeleton_1 = create :skeleton_inventory
      skeleton_2 = build :skeleton_inventory, name: 'My 2nd Skeleton', key: 'my-second-skeleton-key'
      expect(skeleton_2.valid?).to be false
      expect(skeleton_2.errors[:base]).to eq ['A Skeleton spreadsheet already exists.  You cannot create another']
    end
  end

  describe '.exist?' do
    it 'returns false if there is no record with the same name' do
      expect(Inventory.exist?('abc')).to be false
    end

    it 'returns true if there is already a record with the same name' do
      create :inventory, name: 'abc'
      expect(Inventory.exist?('abc')).to be true
    end
  end

  describe '#spreadsheet_url' do
    it 'returns the url for non skeleton spreadsheets' do
      inventory = build :inventory, key: 'my-google-spreadsheet-key'
      expect(inventory.spreadsheet_url).to eq 'https://docs.google.com/spreadsheets/d/my-google-spreadsheet-key'
    end
  end

  describe '.skeleton' do
    it 'returns the skeleton spreadsheet' do
      create :skeleton_inventory
      create :inventory
      skeleton = Inventory.skeleton
      expect(skeleton.name).to eq 'Test skeleton spreadsheet'
      expect(skeleton.key).to eq 'my-dummy-google-skeleton-spreadsheet-key'
      expect(skeleton.is_skeleton?).to be true
    end
  end

  describe 'presented_date_generated' do
    it 'displays the formatted date if present' do
      inventory = build :inventory, date_generated: Time.new(2016, 1, 2, 9, 2,36, 0)
      expect(inventory.presented_date_generated).to eq '2016-01-02 09:02'
    end

    it 'displays NEVER if nil' do
      inventory = build :inventory, date_generated: nil
      expect(inventory.presented_date_generated).to eq 'Never'
    end
  end

  describe '#start_background_job!' do
    it 'saves the record with the flag set to true' do
      inventory = create :inventory, background_job_in_progress: false, flash_notes: nil
      inventory.start_background_job!("There's a background job running")
      inventory.reload
      expect(inventory.background_job_in_progress).to be true
      expect(inventory.flash_notes).to eq "There's a background job running"
    end
  end

  describe '#mark_background_job_error' do
    it 'should mark job as not running, but put the message into flash notes' do
      inventory = create :inventory, background_job_in_progress: true, flash_notes: "Job running"
      inventory.mark_background_job_error("There has been an error")
      inventory.reload
      expect(inventory.background_job_in_progress).to be false
      expect(inventory.flash_notes).to eq "There has been an error"
    end
  end

  describe '.create_pending' do
    it 'should create a dummy record' do
      Timecop.freeze(Time.at(1452374711.7100028)) do
        inventory = Inventory.create_pending('My new spreadsheet')
        expect(inventory.id).not_to be_nil
        expect(inventory.name).to eq 'My new spreadsheet'
        expect(inventory.key).to eq 'pending-key-1452374711.71'
        expect(inventory.background_job_in_progress).to be true
      end
    end
  end

  describe '#mark_creation_complete' do
    it 'should register the key, mark the background job finished and remove the flash notes' do
      inventory = Inventory.create_pending('My new spreadsheet')
      inventory.mark_creation_complete('my-completed-key')
      i2 = Inventory.find(inventory.id)
      expect(i2.key).to eq 'my-completed-key'
      expect(i2.background_job_in_progress).to be false
      expect(i2.flash_notes).to be_nil
    end
  end

  describe '#end_background_job!' do
    it 'saves the record with the flag set to false and wipes the flash note' do
      inventory = create :inventory, background_job_in_progress: true, flash_notes: "XXXXXX"
      inventory.end_background_job!
      inventory.reload
      expect(inventory.background_job_in_progress).to be false
      expect(inventory.flash_notes).to be_nil
    end
  end

  describe 'mark_generated' do
    let(:now)  { Time.now }

    it 'should update the time and save to the db' do
      inventory = create :inventory
      Timecop.freeze(now) do
        inventory.mark_generated
      end
      reloaded_inventory = Inventory.find(inventory.id)
      expect(reloaded_inventory.date_generated.to_i).to eq now.to_i
      expect(reloaded_inventory.background_job_in_progress).to be false
      expect(reloaded_inventory.flash_notes).to be_nil
    end

    it 'should insert time if nil and save to the db' do
      inventory = create :inventory, date_generated: nil
      Timecop.freeze(now) do
        inventory.mark_generated
      end
      reloaded_inventory = Inventory.find(inventory.id)
      expect(reloaded_inventory.date_generated.to_i).to eq now.to_i
      expect(reloaded_inventory.background_job_in_progress).to be false
      expect(reloaded_inventory.flash_notes).to be_nil
    end
  end
end
