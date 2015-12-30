# == Schema Information
#
# Table name: activity_logs
#
#  id           :integer          not null, primary key
#  inventory_id :integer
#  level        :string(255)
#  message      :text
#  created_at   :datetime
#  updated_at   :datetime
#

require 'rails_helper'

RSpec.describe ActivityLog, type: :model do
 
  context 'validations' do
    it 'passes acceptable levels' do
      %W{DEBUG INFO WARN ERROR}.each do |level|
        expect(build(:activity_log, level: level)).to be_valid
      end
    end

    it 'rejects invalid levels' do
      expect(build(:activity_log, level: 'XXXX')).not_to be_valid
    end
  end

  describe '#inventory_name' do
    it 'should return empty string if inventory id is nil' do
      log = build(:activity_log, inventory_id: nil)
      expect(log.inventory_name).to eq ''
    end

    it 'should return the name of the associated inventory' do
      inv = create :inventory, name: "my testing name"
      log = build(:activity_log, inventory_id: inv.id)
      expect(log.inventory_name).to eq 'my testing name'
    end
  end

  describe '#time' do
    it 'formats the created_at time' do
      Timecop.freeze(Time.new(2016,1,12,13,45,56,0)) do
        log = create :activity_log
        expect(log.time).to eq '2016-01-12 13:45:56'
      end
    end
  end

  context 'specialized logger methods' do
    context 'with id' do
      it 'should write an info log' do
        log = ActivityLog.info 'message', 33
        expect(log.level).to eq 'INFO'
        expect(log.inventory_id).to eq 33
      end

      it 'should write an info log' do
        log = ActivityLog.debug 'message', 33
        expect(log.level).to eq 'DEBUG'
        expect(log.inventory_id).to eq 33
      end

      it 'should write an info log' do
        log = ActivityLog.warn 'message', 33
        expect(log.level).to eq 'WARN'
        expect(log.inventory_id).to eq 33
      end

      it 'should write an info log' do
        log = ActivityLog.error 'message', 33
        expect(log.level).to eq 'ERROR'
        expect(log.inventory_id).to eq 33
      end
    end

    context 'without id' do
      it 'should write an info log' do
        log = ActivityLog.info 'message'
        expect(log.level).to eq 'INFO'
        expect(log.inventory_id).to be_nil
      end

      it 'should write an info log' do
        log = ActivityLog.debug 'message'
        expect(log.level).to eq 'DEBUG'
        expect(log.inventory_id).to be_nil
      end

      it 'should write an info log' do
        log = ActivityLog.warn 'message'
        expect(log.level).to eq 'WARN'
        expect(log.inventory_id).to be_nil
      end

      it 'should write an info log' do
        log = ActivityLog.error 'message'
        expect(log.level).to eq 'ERROR'
        expect(log.inventory_id).to be_nil
      end
    end
  end


end
