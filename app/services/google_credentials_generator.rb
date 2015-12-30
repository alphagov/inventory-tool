require 'json'


# This class facilitates setting up new credentials for Inventory Tool to manipulate spreadsheets.
# It expects the user to have downloaded a credential file from Google which will look something like this:
#
#  {
#     "installed":{
#       "client_id":"11111111111-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com",
#       "project_id":"inventory-tool",
#       "auth_uri":"https://accounts.google.com/o/oauth2/auth",
#       "token_uri":"https://accounts.google.com/o/oauth2/token",
#       "auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs",
#       "client_secret":"AAAAAAAAAAAAAA",
#       "redirect_uris":["urn:ietf:wg:oauth:2.0:oob","http://localhost"]
#     }
# }
#
# When we try to instantiate a Google saved session with this file, it will print a url to the console and expect the 
# user to copy and paste it into a browser.  The browser will display a refresh code, which the user should paste into the 
# consle.  The Google auth service will then change the file into something like this:
#
# {
#   "client_id": "681107555901-cko1uonabe9a33aalgep7kfmrulptdgu.apps.googleusercontent.com",  
#   "client_secret": "1U3-Krii5x1oLPrwD5zgn-ry",
#   "scope": [
#     "https://www.googleapis.com/auth/drive",
#     "https://spreadsheets.google.com/feeds/"
#   ],
#   "refresh_token": "1/HDRmaU_jQEjTBWlW9HtBUpIp3JkyYJE9KercWqiYhwk"
# }
#
# This class will then modify the file to replade the client id and client secret with environment variable names and print to the console the 
# environment variable names and values that should be set up.
#

class GoogleCredentialsGenerator

  def initialize
    @client_id = nil
    @client_secret = nil
  end

  def run
    puts "Setting up new Google Credentials - see wiki for details: https://gov-uk.atlassian.net/wiki/pages/viewpage.action?pageId=47677552"
    check_credentials_are_in_config
    get_session_using_new_credentials
    substitute_env_vars
    display_env_vars
  end


  private

  def display_env_vars
    puts "The /config/google_drive_config.json has been transformed and is now safe to check into GitHub."
    puts "\n"
    puts "Please set up the following environment variables on your dev machine, and update the HEROKU environment variables as follows:"
    puts "    GOOGLE_DRIVE_CLIENT_ID=\"#{@client_id}\""
    puts "    GOOGLE_DRIVE_CLIENT_SECRET=\"#{@client_secret}\""
  end

  def substitute_env_vars
    data = JSON.parse(File.read(GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE))
    @client_id = data['client_id']
    data['client_id'] = nil
    @client_secret = data['client_secret']
    data['client_secret'] = nil

    fp = File.open('/Users/stephen/src/gds/inventory-tool/config/new-config.json', 'w')
    fp.write(JSON.pretty_generate(data))
    fp.close
  end

  def check_credentials_are_in_config
    check_config_file_exists
    check_valid_newly_downloaded_config
    confirm_correct_date
  end


  def check_config_file_exists
    unless File.exist?(GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE)
      puts "ERROR: Unable to locate Google credentials in #{GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE}"
      exit 2
    end
  end

  def check_valid_newly_downloaded_config
    config = JSON.parse(File.read(GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE))
    unless config.key?('installed')
      puts "ERROR: The file #{GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE} is not a newly downloaded config file."
      exit 3
    end

    def confirm_correct_date
      puts "#{GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE} was modified at #{File.stat(GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE).mtime}"
      print "Is this the file you want to use? [y/n] "
      response = STDIN.gets.chomp
      unless response == 'y'
        puts "rake task aborted by user"
        exit 4
      end
    end
  end

  def get_session_using_new_credentials
    puts "The Google Authentication process will now display a URL.  Please ensure you are logged in as the Inventory Tool google user "
    puts "before pasting the URL into your browser.  This will ensure that any spreadsheets generated with these credentials are owned "
    puts "by the Inventory Tool user.\n"
    print "Press any key to continue. "
    STDIN.gets
    GoogleCredentials.authenticate_new_credentials
  end

end
