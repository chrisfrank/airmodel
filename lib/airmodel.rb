require 'active_support/all'
require 'airtable'

require "airmodel/version"
require "airmodel/utils"
require "airmodel/associable"
require "airmodel/model"

# builds ActiveRecord-style models on top of Airtable
module Airmodel

  def self.root
    File.expand_path '../..', __FILE__
  end

  def self.client(api_key=ENV["AIRTABLE_API_KEY"])
    @@api_client ||= Airtable::Client.new(api_key)
    @@api_client
  end

  def self.bases(path_to_config_file="#{Dir.pwd}/config/bases.yml")
    @@bases ||= YAML.load_file(path_to_config_file)
    @@bases
  end

end
