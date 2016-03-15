class BaseWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

private

  def log(level, inventory_id, message)
    message = "#{self.class}: #{message}"
    ActivityLog.send(level, message, inventory_id)
  end

  def log_error(inventory_id, error)
    message = "#{self.class}: #{error.class}: #{error.message}\n#{error.backtrace.join("\n")}"
    ActivityLog.error message, inventory_id
  end
end
