require 'spec_helper'

class TestModel < Airmodel::Model
end

class ShardedTestModel < Airmodel::Model
end

class BaselessTestModel < Airmodel::Model
end

describe TestModel do
  let(:config) { Airmodel.bases[:test_models] }

  describe "class_methods" do
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
        stub_airtable_response! "https://api.airtable.com/v0/#{config[:bases]}/#{config[:table_name]}", { "records" => [{"id": "recXYZ", fields: {} }], "offset" => "abcde" }
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
      it "should return a list of airtable records"
    end

    describe "where" do
      it "should return a list of airtable records that match filters"
    end

    describe "find_by" do
      it "should return one record that matches the supplied filters"
    end

    describe "first" do
      it "should return the first record, or nil if there are none"
    end

    describe "create" do
      it "should create a new record"
    end

    describe "patch" do
      it "should update a record"
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
