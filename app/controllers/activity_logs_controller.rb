class ActivityLogsController < ApplicationController

  # GET /activity_logs
  def index
    @activity_logs = ActivityLog.all.order('id DESC').limit(20)
  end

  # GET /activity_logs/1
  def show
    @inventory = Inventory.find params[:id]
    @activity_logs = ActivityLog.for_inventory(@inventory.id)
  end
end
