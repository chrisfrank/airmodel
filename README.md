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

		Song.where("Artist Name" => "The Beatles", "Composer" => "Harrison")

		Song.search(:q => "Let it Be", fields: ["Name", "Album"])

		Song.first

		Song.new("Name": "Best Song Ever").save

		Song.find("recXYZ")

		Song.find_by("Composer" => "Harrison")


Queries are chainable, e.g.

		Song.where("rating" => 5).where('Artist' => "Fiona Apple").order("rating", "DESC").limit(5)

There's also a `Model.by_formula` query, which lets you pass explicit 
[Airtable
Formulas](https://support.airtable.com/hc/en-us/articles/203255215-Formula-field-reference)

You can chain `.limit` and `.order` with a `.by_forumla` query.

		Song.by_formula("NOT({Rating} < 3)").order("rating", "DESC").limit(5)

See `lib/airmodel/model.rb` for all model methods, and
`lib/airmodel/query.rb` for all Query methods.


Contributions
----------------

I'm currently testing against a live Airtable base, because stubbing API
calls has occasionally yielded false positives in my specs. To run the tests,
create an Airtable account, set `AIRTABLE_API_KEY=[your API key]` in your `.env` file, and
then visit [this link](https://airtable.com/invite/l?inviteId=invj96HyFOB6GF8Vq&inviteToken=2e98eff03a646162344bb997a06645e3)
to request access to the base.

Once that's all set, write a passing test for your feature and send a pull request.

Thanks!

