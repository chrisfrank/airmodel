require 'active_support/all'
require 'airtable'

Dir["#{File.dirname(__FILE__)}/airmodel/*.rb"].each {|f| require f }

# builds ActiveRecord-style models on top of Airtable
module Airmodel

  def self.root
    File.expand_path '../..', __FILE__
  end

  def self.client(api_key=ENV["AIRTABLE_API_KEY"])
    @@api_client ||= Airtable::Client.new(api_key)
    @@api_client
  end

  def self.bases(path_to_config_file="#{Airmodel.root}/config/bases.yml")
    @@bases ||= YAML.load_file(path_to_config_file)
    @@bases
  end

end

# monkeypatch airtable-ruby to add v 0.0.9's PATCH method,
# at least until Airtable adds 0.0.9 to rubygems
module Airtable
  class Table

    def update_record_fields(record_id, fields_for_update)
      result = self.class.patch(worksheet_url + "/" + record_id,
        :body => { "fields" => fields_for_update }.to_json,
        :headers => { "Content-type" => "application/json" }).parsed_response
      if result.present? && result["id"].present?
        Record.new(result_attributes(result))
      else # failed
        false
      end
    end

  end
end
