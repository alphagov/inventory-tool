# This class is necessary because we want to keep the client-id and client-secret
# out of files we check into GitHub. So we create a file on demand in temp storage and merge in the 
# client id and secret on

class GoogleCredentials

  SKELETON_CONFIG_FILE = "#{Rails.root}/config/google_drive_config.json"
  
  def self.saved_session
    tempfile = generate_tempfile
    session = GoogleDrive.saved_session(tempfile.path)
    tempfile.unlink
    session
  end

  def self.generate_tempfile
    credentials = JSON.parse(File.read(SKELETON_CONFIG_FILE))
    credentials['client_id'] = ENV['GOOGLE_DRIVE_CLIENT_ID']
    credentials['client_secret'] = ENV['GOOGLE_DRIVE_CLIENT_SECRET']

    tempfile = Tempfile.new(%w{ google .json })
    tempfile.puts credentials.to_json
    tempfile.close
    tempfile
  end

  # This method is used to generate the refresh token when setting up new credentials - ssee README
  def self.authenticate_new_credentials
    @session = GoogleDrive.saved_session(SKELETON_CONFIG_FILE)
  end

end
