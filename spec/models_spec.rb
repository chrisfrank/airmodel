require 'spec_helper'

class TestModel < Airmodel::Model
end

class ShardedTestModel < Airmodel::Model
end

class BaselessTestModel < Airmodel::Model
end

describe TestModel do

  before(:each) do
    config = Airmodel.bases[:test_models]
    stub_airtable_response!(
      Regexp.new("https://api.airtable.com/v0/#{config[:bases]}/#{config[:table_name]}"),
      { "records" => [{"id": "recXYZ", fields: {"color":"red"} }, {"id":"recABC", fields: {"color": "blue"} }] }
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

    describe "records" do
      it "should return a list of airtable records" do
        records = TestModel.records
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
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table",
          { "fields" => { "color" => "red", "foo" => "bar" }, "id" => "12345" },
          :post
        )
        record = TestModel.create(color: "red")
        expect(record.id).to eq "12345"
      end
    end

    describe "patch" do
      it "should update a record" do
        stub_airtable_response!("https://api.airtable.com/v0/appXYZ/example_table",
          { "fields" => { "color" => "red", "foo" => "bar" }, "id" => "12345" },
          :post
        )
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
      it "should create a new record"
      it "should update an existing record"
    end
    describe "destroy" do
      it "should delete a record"
    end
    describe "update" do
      it "should update the supplied attrs on an existing record"
    end
    describe "cache_key" do
      it "should return a unique key that can be used to id this record in memcached"
    end
    describe "changed_fields" do
      it "should return a hash of attrs changed since last save"
    end
    describe "new_record?" do
      it "should return true if the record hasn't been saved to airtable yet"
    end
    describe "formatted_fields" do
      it "should convert empty arrays [''] to []"
    end
  end
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
