require 'rails_helper'

describe GoogleCredentials do

  describe '.authenticate_new_credentials' do
    it 'should create a new saved_session' do
      expect(GoogleDrive).to receive(:saved_session).with(GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE)
      GoogleCredentials.authenticate_new_credentials
    end
  end

  describe '.saved_session' do
    it 'should create and then delete a config file with cient id and secret' do
      ENV['GOOGLE_DRIVE_CLIENT_ID'] = 'my-client-id'
      ENV['GOOGLE_DRIVE_CLIENT_SECRET'] = 'my-client-secret'
      session = double('GoogleDrive Saved Session')
      tempfile = double(Tempfile)

      expect(Tempfile).to receive(:new).and_return(tempfile)
      expect(tempfile).to receive(:path).and_return('/path/to/my/tempfile')
      expect(tempfile).to receive(:puts).with(json_credentials)
      expect(tempfile).to receive(:close)
      expect(tempfile).to receive(:unlink)

      expect(GoogleDrive).to receive(:saved_session).with('/path/to/my/tempfile').and_return(session)

      new_session = GoogleCredentials.saved_session
      expect(new_session).to eq session
    end
  end

  def json_credentials
    {
      'client_id' => 'my-client-id',
      'client_secret' => 'my-client-secret',
      'scope' =>  [
        'https://www.googleapis.com/auth/drive',
        'https://spreadsheets.google.com/feeds/'
      ],
      'refresh_token' => '1/AUNh1aOdTESQBa4f4xqE5qVHNGnO-_2dEi4hF1woPYdIgOrJDtdun6zK6XiATCKT'
    }.to_json
  end
end
