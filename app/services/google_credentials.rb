class GoogleCredentials
  def self.saved_session
    Tempfile.create('google_secrets') do |tempfile|
      tempfile.puts credentials.to_json
      tempfile.flush
      GoogleDrive.saved_session(tempfile.path)
    end
  end

  def self.do_auth_handshake
    Tempfile.create('google_secrets') do |tempfile|
      tempfile.puts credentials.to_json
      tempfile.flush
      GoogleDrive.saved_session(tempfile.path)
      data = JSON.parse(File.read(tempfile.path))
      data['refresh_token']
    end
  end

  def self.credentials
    {
      'client_id' => ENV['GOOGLE_DRIVE_CLIENT_ID'],
      'client_secret' => ENV['GOOGLE_DRIVE_CLIENT_SECRET'],
      'refresh_token' => ENV['GOOGLE_DRIVE_REFRESH_TOKEN'],
    }
  end
end
