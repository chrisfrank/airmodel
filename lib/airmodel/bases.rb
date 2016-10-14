module Airmodel

  module Bases

    def self.load(path_to_config_file="#{Dir.pwd}/config/database.yml")
      @@bases ||= YAML.load_file(path_to_config_file)
      @@bases
    end

    def self.client
      @@api_client ||= Airtable::Client.new(ENV["AIRTABLE_API_KEY"])
      @@api_client
    end

  end
end
