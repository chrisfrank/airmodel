require "airmodel"
require "pry"
require "vcr"
require "dotenv"
Dotenv.load

RSpec.configure do |config|
  config.color = true
  config.extend VCR::RSpec::Macros
  config.order = :random
end

VCR.configure do |config| config.allow_http_connections_when_no_cassette = true
  config.cassette_library_dir = "#{Airmodel.root}/spec/fixtures/vcr_cassettes"
  config.default_cassette_options = { :record => :new_episodes }
  config.filter_sensitive_data("<AIRTABLE_API_KEY>") { ENV.fetch('AIRTABLE_API_KEY') }
end

# enable Debug mode in Airtable
module Airtable
  # Base class for authorized resources sending network requests
  class Resource
    include HTTParty
    base_uri 'https://api.airtable.com/v0/'
    debug_output $stdout

    attr_reader :api_key, :app_token, :worksheet_name

    def initialize(api_key, app_token, worksheet_name)
      @api_key = api_key
      @app_token = app_token
      @worksheet_name = worksheet_name
      self.class.headers({'Authorization' => "Bearer #{@api_key}"})
    end
  end # AuthorizedResource
end # Airtable
