require 'rails_helper'

describe GoogleCredentials do

  describe '.authenticate_new_credentials' do
    it 'should create a new saved_session' do
      expect(GoogleDrive).to receive(:saved_session).with(GoogleSpreadsheet::GOOGLE_DRIVE_CONFIG_FILE)
      GoogleCredentials.authenticate_new_credentials
    end
  end

  describe '.saved_session' do
    it 'should create and then delete a config file with client id and secret' do
      allow(ENV).to receive(:[]).with('GOOGLE_DRIVE_CLIENT_ID').and_return('my-client-id')
      allow(ENV).to receive(:[]).with('GOOGLE_DRIVE_CLIENT_SECRET').and_return('my-client-secret')
      saved_session = double('GoogleDrive Saved Session')
      dummy_tempfile = double(Tempfile)
      allow(Tempfile).to receive(:new).and_return(dummy_tempfile)
      allow(dummy_tempfile).to receive(:path).and_return('/path/to/my/dummy_tempfile')

      expect(dummy_tempfile).to receive(:puts) do |file|
        file_content = JSON.parse file
        expect(file_content).to include('client_id' => 'my-client-id')
        expect(file_content).to include('client_secret' => 'my-client-secret')
      end
      expect(dummy_tempfile).to receive(:close)
      expect(dummy_tempfile).to receive(:unlink)
      expect(GoogleDrive).to receive(:saved_session).with('/path/to/my/dummy_tempfile').and_return(saved_session)

      expect(GoogleCredentials.saved_session).to eq saved_session
    end
  end
end
