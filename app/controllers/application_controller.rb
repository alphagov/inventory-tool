class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from StandardError, with: :log_error

  def log_error(exception)
    message = "#{exception.class}: #{exception.message}\n#{exception.backtrace.join("\n")}"
    ActivityLog.create(level: :error, message: message)
    flash[:danger] = "An excpetion has been trapped - view ActivityLogs for details"
    redirect_to errors_path
  end
end
