require 'json'

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

    File.open('config/google_drive_config.json', 'w') do |config_file|
      config_file.write(JSON.pretty_generate(data))
    end
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
