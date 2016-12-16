require 'spec_helper'

class Album < Airmodel::Model
end

describe Album do

  before(:each) do
    config = Airmodel.bases[:albums]
    #stub INDEX requests
    stub_airtable_response!(
      Regexp.new("https://api.airtable.com/v0/#{config[:base_id]}/#{config[:table_name]}"),
      { "records" => [{"id": "recXYZ", fields: {"color":"red"} }, {"id":"recABC", fields: {"color": "blue"} }] }
    )
    #stub CREATE requests
    stub_airtable_response!("https://api.airtable.com/v0/appXYZ/albums",
      { "fields" => { "color" => "red", "foo" => "bar" }, "id" => "12345" },
      :post
    )
  end

  after(:each) do
    FakeWeb.clean_registry
  end

  describe "Class Methods" do
    describe "table" do
      it "should return an Airtable::Table object" do
        table = Album.table
        expect(table.class).to eq Airtable::Table
        expect(table.app_token).not_to eq nil
      end
    end

    describe "at" do
      it "should connect to an arbitrary base and table" do
        table = Album.at("hello", "world")
        expect(table.class).to eq Airtable::Table
      end
    end

    describe "classify" do
      it "should return albums from Airtable::Records" do
        array = [Airtable::Record.new]
        results = Album.classify(array)
        expect(results.first.class).to eq Album
      end
    end

    describe "all" do
      it "should return a list of airtable records" do
        records = Album.all
        expect(records.first.id).to eq "recXYZ"
      end
    end

    describe "where" do
      it "should return a list of airtable records that match filters" do
        records = Album.where(color: "red")
        expect(records.first.class).to eq Album
        expect(records.first.color).to eq "red"
      end
    end

    describe "find" do
      it "should call airtable-ruby's 'find' method when passed just one record ID" do
        stub_airtable_response! "https://api.airtable.com/v0/appXYZ/albums/recABC", { "id":"recABC", fields: {"name": "example record"} }
        record = Album.find("recABC")
        expect(record.name).to eq "example record"
      end
      it "should return an ordered list of records when passed an array of record IDs" do
        records = Album.find(["recABC", "recXYZ"])
        expect(records.class).to eq Array
        expect(records.first.id).to eq "recABC"
        expect(records.first.class).to eq Album
      end
    end

    describe "find_by" do
      it "should return one record that matches the supplied filters", skip_before: true do
        stub_airtable_response!(
          Regexp.new("https://api.airtable.com/v0/appXYZ/albums"),
          { "records" => [{"id":"recABC", fields: {"color": "blue"} }] }
        )
        record = Album.find_by(color: "blue")
        expect(record.color).to eq "blue"
        expect(record.class).to eq Album
      end
      it "should call airtable-ruby's 'find' method when the filter is an id" do
        stub_airtable_response! "https://api.airtable.com/v0/appXYZ/albums/recABC", { "id":"recABC", fields: {"name": "example record"} }
        record = Album.find_by(id: "recABC")
        expect(record.name).to eq "example record"
        expect(record.class).to eq Album
      end
    end

    describe "first" do
      it "should return the first record" do
        record = Album.first
        expect(record.class).to eq Album
      end
    end

    describe "create" do
      it "should create a new record" do
        record = Album.create(color: "red")
        expect(record.id).to eq "12345"
      end
    end

    describe "patch" do
      it "should update a record" do
        stub_airtable_response!(Regexp.new("/v0/appXYZ/albums/12345"),
          { "fields" => { "color" => "blue", "foo" => "bar" }, "id" => "12345" },
          :patch
        )
        record = Album.create(color: "red")
        record = Album.patch("12345", { color: "blue" })
        expect(record.color).to eq "blue"
      end
    end

  end

  describe "Instance Methods" do

    describe "save" do
      record = Album.new(color: "red")
      it "should create a new record" do
        record.save
        expect(record.id).to eq "12345"
      end
      it "should update an existing record" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/albums/12345",
          { "fields" => { "color" => "red", "foo" => "bar" }, "id" => "12345" },
          :get
        )
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/albums/12345",
          { "fields" => { "color" => "blue" }, "id" => "12345" },
          :patch
        )
        record[:color] = "blue"
        record.save
        expect(record.color).to eq "blue"
      end
    end

    describe "destroy" do
      it "should delete a record" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/albums/12345",
          { "deleted": true, "id" => "12345" },
          :delete
        )
        response = Album.new(id: "12345").destroy
        expect(response["deleted"]).to eq true
      end
    end

    describe "update" do
      it "should update the supplied attrs on an existing record" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/albums/12345",
          { "fields" => { "color" => "green"}, "id" => "12345" },
          :patch
        )
        record = Album.create(color: "red", id:"12345")
        record.update(color: "green")
        expect(record.color).to eq "green"
      end
    end

    describe "cache_key" do
      it "should return a unique key that can be used to id this record in memcached" do
        record = Album.new(id: "recZXY")
        expect(record.cache_key).to eq "albums_recZXY"
      end
    end

    describe "changed_fields" do
      it "should return a hash of attrs changed since last save" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/albums/12345",
          { fields: { 'color': 'red' }, "id" => "12345" },
          :get
        )
        record = Album.create(color: 'red')
        record[:color] = 'green'
        expect(record.changed_fields).to have_key 'color'
      end
    end

    describe "new_record?" do
      it "should return true if the record hasn't been saved to airtable yet" do
        record = Album.new(color: 'red')
        expect(record.new_record?).to eq true
      end
    end

    describe "formatted_fields" do
      attrs = {
        "empty_array": [''],
        "empty_array_bis": [""],
        "blank_string": "",
        "truthy_string": "true",
        "falsy_string": "false"
      }
      record = Album.new(attrs)
      formatted_attrs = record.formatted_fields
      it "should convert empty arrays [''] to []" do
        expect(formatted_attrs["empty_array"]).to eq []
        expect(formatted_attrs["empty_array_bis"]).to eq []
      end
      it "should convert blank strings to nil" do
        expect(formatted_attrs["blank_string"]).to eq nil
      end
      it "should convert 'true' to a boolean" do
        expect(formatted_attrs["truthy_string"]).to eq true
      end
      it "should convert 'false' to a boolean" do
        expect(formatted_attrs["falsy_string"]).to eq false
      end
    end

  end
end

class BaselessModel < Airmodel::Model
end

describe BaselessModel do
  describe "it should raise a NoSuchBaseError when no base is defined" do
    begin
      records = BaselessModel.all
      false
    rescue Airmodel::NoSuchBase
      true
    end
  end
end
