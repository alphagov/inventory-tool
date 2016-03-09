class Inventory < ActiveRecord::Base
  validates :name, presence: {message: "You must specify a name" }
  validates :name, uniqueness: {message: "There is already an inventory spreadsheet with the same name"}
  validates :key, presence: {message: "System Error: No key has been specified"}
  validate :only_one_skeleton

  def self.skeleton
    self.where(is_skeleton: true).first
  end

  def self.all_ordered
    self.all.order('is_skeleton DESC, name ASC')
  end

  def self.exist?(name)
    Inventory.where(name: name).any?
  end

  def self.create_pending(name)
    self.create(
      name: name,
      key: "pending-key-#{Time.now.to_f.round(2)}",
      background_job_in_progress: true,
      flash_notes: "Spreadsheet has been queued for creation. Reload page in a few seconds to view."
    )
  end

  def log(level, message)
    ActivityLog.send(level, message, self.id)
  end

  def mark_creation_complete(key)
    update_attributes(key: key, date_generated: Time.now, background_job_in_progress: false, flash_notes: nil)
  end

  def only_one_skeleton
    if is_skeleton?
      pre_existing_skeleton = Inventory.skeleton
      unless pre_existing_skeleton.nil?
        errors.add(:base, "A Skeleton spreadsheet already exists.  You cannot create another")
      end
    end
  end

  def spreadsheet_url
    "https://docs.google.com/spreadsheets/d/#{key}"
  end

  def presented_date_generated
    self.date_generated.nil? ? 'Never' : self.date_generated.strftime("%Y-%m-%d %H:%M")
  end

  def mark_generated
    update_attributes(date_generated: Time.now, background_job_in_progress: false, flash_notes: nil)
  end

  def start_background_job!(message)
    log(:info, message)
    update_attributes(background_job_in_progress: true, flash_notes: message)
  end

  def end_background_job!
    update_attributes(background_job_in_progress: false, flash_notes: nil)
  end

  def mark_background_job_error(message)
    update_attributes(background_job_in_progress: false, flash_notes: message)
  end
end
