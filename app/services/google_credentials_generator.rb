require 'json'

class GoogleCredentialsGenerator
  def run
    puts "Setting up new Google Credentials - see wiki for details: https://gov-uk.atlassian.net/wiki/pages/viewpage.action?pageId=47677552"

    if ENV['GOOGLE_DRIVE_CLIENT_ID'].nil? || ENV['GOOGLE_DRIVE_CLIENT_SECRET'].nil?
      raise "Set the GOOGLE_DRIVE_CLIENT_ID and GOOGLE_DRIVE_CLIENT_SECRET environment variables"
    end

    refresh_token = get_session_using_new_credentials
    display_env_vars(refresh_token)
  end

private

  def display_env_vars(refresh_token)
    puts "Set the following environment variable for the running app"
    puts "    GOOGLE_DRIVE_REFRESH_TOKEN=\"#{refresh_token}\""
  end

  def get_session_using_new_credentials
    puts "The Google Authentication process will now display a URL.  Please ensure you are logged in as the Inventory Tool google user "
    puts "before pasting the URL into your browser.  This will ensure that any spreadsheets generated with these credentials are owned "
    puts "by the Inventory Tool user.\n"
    print "Press any key to continue. "
    STDIN.gets
    GoogleCredentials.do_auth_handshake
  end
end
