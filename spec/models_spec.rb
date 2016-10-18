require 'spec_helper'

class TestModel < Airmodel::Model
end

describe TestModel do

  before(:each) do
    config = Airmodel.bases[:test_models]
    #stub INDEX requests
    stub_airtable_response!(
      Regexp.new("https://api.airtable.com/v0/#{config[:bases]}/#{config[:table_name]}"),
      { "records" => [{"id": "recXYZ", fields: {"color":"red"} }, {"id":"recABC", fields: {"color": "blue"} }] }
    )
    #stub CREATE requests
    stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table",
      { "fields" => { "color" => "red", "foo" => "bar" }, "id" => "12345" },
      :post
    )
  end

  after(:each) do
    FakeWeb.clean_registry
  end

  describe "Class Methods" do
    describe "tables" do
      it "should return Airtable::Table objects for each base in the config file" do
        tables = TestModel.tables
        tables.each do |t|
          expect(t.class).to eq Airtable::Table
          expect(t.app_token).not_to eq nil
        end
      end
    end

    describe "at" do
      it "should connect to an arbitrary base and table" do
        table = TestModel.at("hello", "world")
        expect(table.class).to eq Airtable::Table
      end
    end

    describe "some" do
      it "should return a list of airtable records" do
        records = TestModel.some
        expect(records.first.id).to eq "recXYZ"
      end
    end

    describe "classify" do
      it "should return TestModels from Airtable::Records" do
        array = [Airtable::Record.new]
        results = TestModel.classify(array)
        expect(results.first.class).to eq TestModel
      end
    end

    describe "all" do
      it "should return a list of airtable records" do
        records = TestModel.all
        expect(records.first.id).to eq "recXYZ"
      end
    end

    describe "where" do
      it "should return a list of airtable records that match filters" do
        records = TestModel.where(color: "red")
        expect(records.first.class).to eq TestModel
        expect(records.first.color).to eq "red"
      end
    end

    describe "find_by" do
      it "should return one record that matches the supplied filters", skip_before: true do
        stub_airtable_response!(
          Regexp.new("https://api.airtable.com/v0/appXYZ/example_table"),
          { "records" => [{"id":"recABC", fields: {"color": "blue"} }] }
        )
        record = TestModel.find_by(color: "blue")
        expect(record.color).to eq "blue"
      end
      it "should call airtable-ruby's 'find' method when the filter is an id" do
        stub_airtable_response! "https://api.airtable.com/v0/appXYZ/example_table/recABC", { "id":"recABC", fields: {"name": "example record"} }
        record = TestModel.find_by(id: "recABC")
        expect(record.name).to eq "example record"
      end
    end

    describe "first" do
      it "should return the first record" do
        record = TestModel.first
        expect(record.class).to eq TestModel
      end
    end

    describe "create" do
      it "should create a new record" do
        record = TestModel.create(color: "red")
        expect(record.id).to eq "12345"
      end
    end

    describe "patch" do
      it "should update a record" do
        stub_airtable_response!(Regexp.new("/v0/appXYZ/example_table/12345"),
          { "fields" => { "color" => "blue", "foo" => "bar" }, "id" => "12345" },
          :patch
        )
        record = TestModel.create(color: "red")
        record = TestModel.patch("12345", { color: "blue" })
        expect(record.color).to eq "blue"
      end
    end

  end

  describe "Instance Methods" do

    describe "save" do
      record = TestModel.new(color: "red")
      it "should create a new record" do
        record.save
        expect(record.id).to eq "12345"
      end
      it "should update an existing record" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table/12345",
          { "fields" => { "color" => "red", "foo" => "bar" }, "id" => "12345" },
          :get
        )
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table/12345",
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
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table/12345",
          { "deleted": true, "id" => "12345" },
          :delete
        )
        response = TestModel.new(id: "12345").destroy
        expect(response["deleted"]).to eq true
      end
    end

    describe "update" do
      it "should update the supplied attrs on an existing record" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table/12345",
          { "fields" => { "color" => "green"}, "id" => "12345" },
          :patch
        )
        record = TestModel.create(color: "red", id:"12345")
        record.update(color: "green")
        expect(record.color).to eq "green"
      end
    end

    describe "cache_key" do
      it "should return a unique key that can be used to id this record in memcached" do
        record = TestModel.new(id: "recZXY")
        expect(record.cache_key).to eq "test_models_recZXY"
      end
    end

    describe "changed_fields" do
      it "should return a hash of attrs changed since last save" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table/12345",
          { fields: { 'color': 'red' }, "id" => "12345" },
          :get
        )
        record = TestModel.create(color: 'red')
        record[:color] = 'green'
        expect(record.changed_fields).to have_key 'color'
      end
    end

    describe "new_record?" do
      it "should return true if the record hasn't been saved to airtable yet" do
        record = TestModel.new(color: 'red')
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
      record = TestModel.new(attrs)
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

class ShardedTestModel < Airmodel::Model
end

describe ShardedTestModel do
  let(:config) { Airmodel.bases[:test_models_sharded] }

  describe "class_methods" do

    describe "tables" do
      it "should return Airtable::Table objects for each base in the config file" do
        tables = ShardedTestModel.tables
        tables.each do |t|
          expect(t.class).to eq Airtable::Table
          expect(t.app_token.class).to eq String
        end
      end
      it "should return just the one table matching args[:shard]" do
        tables = ShardedTestModel.tables(shard: "east_coast")
      end
    end

    describe "normalized_base_config" do
      it "should return a hash from a string" do
        sample_config = "appXYZ"
        target = { "appXYZ" => "appXYZ" }
        expect(TestModel.normalized_base_config(sample_config)).to eq target
      end
      it "should return a hash from an array of strings" do
        sample_config = %w(appXYZ appABC)
        target = { "appXYZ" => "appXYZ", "appABC" => "appABC" }
        expect(TestModel.normalized_base_config(sample_config)).to eq target
      end
      it "should return a hash from an array of hashes" do
        sample_config = [{"nyc": "appXYZ"}, {"sf": "appABC"}]
        target = { "nyc": "appXYZ", "sf": "appABC" }
        expect(TestModel.normalized_base_config(sample_config)).to eq target
      end
      it "should return itself from a hash" do
        sample_config = {"nyc": "appXYZ", "sf": "appABC" }
        target = { "nyc": "appXYZ", "sf": "appABC" }
        expect(TestModel.normalized_base_config(sample_config)).to eq target
      end
    end

  end
end

class BaselessTestModel < Airmodel::Model
end

describe BaselessTestModel do
  describe "it should raise a NoSuchBaseError when no base is defined" do
    begin
      records = BaselessTestModel.some
      false
    rescue Airmodel::NoSuchBase
      true
    end
  end
end
