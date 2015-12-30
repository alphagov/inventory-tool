class ErrorsController < ApplicationController

  def index
    @log = ActivityLog.last
  end

end
