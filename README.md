Airmodel
===========

Interact with your Airtable data using ActiveRecord-style models.

Installation
----------------

Add this line to your Gemfile:

		gem install 'airmodel'

Configuration
----------------
1. Supply your Airtable API key, either by setting ENV['AIRTABLE_API_KEY']
before your app starts...

		ENV['AIRTABLE_API_KEY'] = YOUR_API_KEY

	... or by putting this line somewhere in your app's init block:

		Airmodel.client(YOUR_API_KEY_HERE)

2. Tell Airmodel where your bases are, either by creating a YAML file at
*config/bases.yml*, or with this line somewhere in your init block:

		Airmodel.bases(path_to_your_yaml_file)

	Your YAML file should look something like this:

		:songs:
			:table_name: Songs
			:base_id: appXYZ123ABC
		:albums:
			:table_name: Albums
			:base_id: appZZTOPETC


Usage
----------------

Create a class for each key in your YAML file. You should name it after the 
singularized version of your YAML key:

		class Song < Airmodel::Model
		end

		class Album < Airmodel::Model
		end

Now you can write code like

		Song.all

		Song.some

		Song.first

		Song.new("Name": "Best Song Ever").save

		Song.where("Artist Name": "The Beatles", "Composer": "Harrison")

		Song.find("recXYZ")

		Song.find(["recXYZ", "recABC", "recJKL"])

See lib/airmodel/model.rb for all available methods.


Contributions
----------------

Add a test to spec/models_spec.rb, make sure it passes, then send a pull
request. Thanks!


