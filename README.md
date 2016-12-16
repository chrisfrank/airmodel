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

		Song.where("Artist Name": "The Beatles", "Composer": "Harrison")

		Song.first

		Song.new("Name": "Best Song Ever").save

		Song.find("recXYZ")

		Song.find(["recXYZ", "recABC", "recJKL"])


Most queries are chainable, e.g.

		Song.where("rating" => 5).where('artist' => "Fiona Apple").order("rating", "DESC").limit(5)

There's also a special `Model.by_formula` query, which overrides any filters
supplied in your `Model.where()` statements, and replaces them with a raw
[Airtable
Formula](https://support.airtable.com/hc/en-us/articles/203255215-Formula-field-reference)

You can still chain `.limit` and `.order` with a `.by_forumla` query.

		Song.by_formula("NOT({Rating} < 3)").order("rating", "DESC").limit(5)

See lib/airmodel/model.rb for all available methods.


Contributions
----------------

Add a passing test to spec/model_spec.rb, then send a pull
request. Thanks!


