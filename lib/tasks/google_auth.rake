require File.dirname(__FILE__) + '/../../app/services/google_credentials_generator'
require File.dirname(__FILE__) + '/../../app/services/google_credentials'
require File.dirname(__FILE__) + '/../../app/models/google_spreadsheet'

namespace :google do
  desc 'configure app to use newly-created Google credentials'
  task :auth do
    GoogleCredentialsGenerator.new.run
  end
end
