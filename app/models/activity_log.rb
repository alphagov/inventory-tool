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

class ActivityLog

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
    output = output_to(level)
    log_message = {
      level: level,
      message: message,
      inventory_id: inventory_id,
      time: Time.now,
    }.to_json
    output.puts log_message
  end

  def self.output_to(level = :error)
    level == :error ? STDERR : STDOUT
  end
end
