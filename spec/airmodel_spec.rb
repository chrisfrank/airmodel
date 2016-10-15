require 'spec_helper'
describe Airmodel do

  describe "bases" do
    it 'should load Airtable base configuration from a YAML file' do
      db = Airmodel.bases
      expect(db).to eq YAML.load_file("#{Airmodel.root}/config/bases.yml")
    end
  end

  describe "client" do
    it 'should return a connected Airtable API client' do
      client = Airmodel.client
      expect(client.class).to eq Airtable::Client
    end
  end

end
