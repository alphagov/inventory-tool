class DatabasePruner
  DEVELOPMENT_DEBUG_CUTOFF_TIME = 2.hours.ago
  DEVELOPMENT_PRUNE_TIME = 4.hours.ago
  PRODUCTION_DEBUG_CUTOFF_TIME = 36.hours.ago
  PRODUCTION_PRUNE_TIME = 48.hours.ago

  def initialize
    @debug_cutoff_time = Rails.env.development? ? DEVELOPMENT_DEBUG_CUTOFF_TIME : PRODUCTION_DEBUG_CUTOFF_TIME
    @cutoff_time = Rails.env.development? ? DEVELOPMENT_PRUNE_TIME : PRODUCTION_PRUNE_TIME
  end

  def run
    before_count = ActivityLog.count

    old_debugs = ActivityLog.where('level = ? and created_at < ?', 'DEBUG', @debug_cutoff_time)
    ActivityLog.delete(old_debugs.map(&:id))

    just_old = ActivityLog.where('created_at < ?', @cutoff_time)
    ActivityLog.delete(just_old.map(&:id))    

    deleted_inventory_logs = ActivityLog.where('inventory_id not in (?) ', Inventory.pluck(:id))
    ActivityLog.delete(deleted_inventory_logs.map(&:id))

    after_count = ActivityLog.count
    ActivityLog.debug "Database pruned, number of activity logs reduced from #{before_count} to #{after_count}"
  end
end
