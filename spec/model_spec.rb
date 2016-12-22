require 'spec_helper'

class Album < Airmodel::Model
end

describe Album do

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
      use_vcr_cassette
      it "should return a list of airtable records" do
        records = Album.all
        expect(records.first.id).to eq "rec0bTuIoUQVPMsmi"
      end
    end

    describe "where" do
      use_vcr_cassette
      it "should return a list of airtable records that match filters" do
        records = Album.where(name: "Blood on the Tracks")
        expect(records.first.class).to eq Album
        expect(records.first.name).to eq "Blood on the Tracks"
      end
    end

    describe "find" do
      use_vcr_cassette
      it "should call airtable-ruby's 'find' method when passed just one record ID" do
        record = Album.find("rec52DfV4E2I2kzrS")
        expect(record.name).to eq "Voodoo"
      end
      it "should return an ordered list of records when passed an array of record IDs" do
        records = Album.find(["rec52DfV4E2I2kzrS", "rec0bTuIoUQVPMsmi"])
        expect(records.class).to eq Array
        expect(records.first.id).to eq "rec52DfV4E2I2kzrS"
        expect(records.first.class).to eq Album
      end
    end

    describe "find_by" do
      use_vcr_cassette
      it "should return one record that matches the supplied filters" do
        record = Album.find_by(name: "Voodoo")
        expect(record.name).to eq "Voodoo"
        expect(record.class).to eq Album
      end
    end

    describe "first" do
      use_vcr_cassette
      it "should return the first record" do
        record = Album.first
        expect(record.class).to eq Album
      end
    end

    describe "create" do
      use_vcr_cassette
      it "should create a new record" do
        record = Album.create("Name" => "Abbey Road")
        expect(record.id).not_to eq nil
        record.destroy
      end
    end

    describe "patch" do
      use_vcr_cassette
      it "should update a record" do
        record = Album.create("Name" => "Let It Be")
        notes = "It wasn't really their last one"
        record = Album.patch(record.id, { "Notes" => notes })
        expect(record.notes).to eq notes
        record.destroy
      end
    end

  end

  describe "Instance Methods" do

    describe "save" do
      record = Album.new("Name" => "His California Record")
      it "should create a new record" do
        record.save
        expect(record.id).not_to be nil
      end
      it "should update an existing record" do
        record["Artist"] = "Bobby Bland"
        record.save
        expect(record.artist).to eq "Bobby Bland"
        record.destroy
      end
    end

    describe "destroy" do
      it "should delete a record" do
        response = Album.create("Name" => "12345").destroy
        expect(response["deleted"]).to eq true
      end
    end

    describe "update" do
      it "should update the supplied attrs on an existing record" do
        record = Album.create("Name" => "Blue")
        record.update("Name" => "Green")
        expect(record.name).to eq "Green"
        record.destroy
      end
    end

    describe "cache_key" do
      it "should return a unique key that can be used to id this record in memcached" do
        record = Album.first
        expect(record.cache_key).to eq "albums_#{record.id}"
      end
    end

    describe "changed_fields" do
      it "should return a hash of attrs changed since last save" do
        record = Album.create("Name" => "Pinkerton")
        record["Name"] = "Green"
        expect(record.changed_fields).to have_key "Name"
        record.destroy
      end
    end

    describe "new_record?" do
      it "should return true if the record hasn't been saved to airtable yet" do
        record = Album.new("Name" => "Jim!")
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
