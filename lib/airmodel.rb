require 'active_support/all'
require 'airtable'

Dir["#{File.dirname(__FILE__)}/airmodel/*.rb"].each {|f| require f }

# builds ActiveRecord-style models on top of Airtable
module Airmodel
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
