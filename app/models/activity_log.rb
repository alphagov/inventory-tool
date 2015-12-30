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

class ActivityLog < ActiveRecord::Base

  belongs_to :inventory

  validates :level, inclusion: { in: %w(DEBUG INFO WARN ERROR), message: "%{value} in not a valid level for ActivityLog." }

  before_validation do
    self.level = self.level.to_s.upcase
  end

  def inventory_name
    self.inventory.nil? ? "" : self.inventory.name
  end

  def self.for_inventory(inventory_id)
    self.where('inventory_id = ?', inventory_id).order('id DESC')
  end

  def time
    self.created_at.strftime('%Y-%m-%d %H:%M:%S')
  end

  def self.info(message, inventory_id = nil)
    log(:info, message, inventory_id)
  end

  def self.warn(message, inventory_id = nil)
    log(:warn, message, inventory_id)
  end

  def self.debug(message, inventory_id = nil)
    log(:debug, message, inventory_id)
  end

  def self.error(message, inventory_id = nil)
    log(:error, message, inventory_id)
  end

  def self.log(level, message, inventory_id)
    self.create(inventory_id: inventory_id, level: level, message: message)
  end
end
