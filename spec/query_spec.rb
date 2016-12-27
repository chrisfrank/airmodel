require "spec_helper"

class Album < Airmodel::Model
end

describe Album do

  describe "where" do
    it "allows chaining" do
      q = Album.where(
        "name" => "Tidal",
        "artist" => "Fiona Apple"
      ).limit(10).order("Name DESC")
      expect(q.class).to eq Airmodel::Query
      # it should execute the query on
      # query.all, and return an array
      expect(q.all.class).to be Array
      expect(q.count).to eq 1
    end

    it "can use a raw airtable formula" do
      formula = "NOT({Rating} > 3)"
      q = Album.by_formula(formula)
      expect(q.params[:formulas].to_s).to eq [formula].to_s
      expect(q.all.class).to be Array
      expect(q.count).to eq 1
    end
  end

  describe "limit" do
    it "limits the results to the specified number" do
      q = Album.limit(2)
      expect(q.count).to eq 2
    end

    it "accepts a string instead of an integer" do
      q = Album.limit("1")
      expect(q.count).to eq 1
    end

    it "accepts nil as an all-pass filter" do
      q = Album.limit(nil)
      expect(q.count).to eq Album.all.count
    end
  end

  describe "search" do
    it "searches in args[:fields] for args[:value]" do
      q = Album.search(q: "Fiona", fields: ["Artist"])
      expect(q.count).to eq 1
      expect(q.first.artist).to eq "Fiona Apple"
    end

    it "can search across multiple fields" do
      q = Album.search(q: "Sinatra", fields: ["Artist", "Name"])
      expect(q.count).to eq 2
      expect(q.first.artist).to eq "Frank Sinatra"
      expect(q.last.artist).to eq "Dylan"
    end

    it "can accept field names as a string" do
      q = Album.search(q: "Sinatra", fields: "Artist, Name")
      expect(q.count).to eq 2
      expect(q.first.artist).to eq "Frank Sinatra"
      expect(q.last.artist).to eq "Dylan"
    end

    it "is not case-sensitive w/r/t queries" do
      q = Album.search(q: "dylan", fields: "Artist")
      expect(q.count).to eq 2
    end

    it "accepts nil as an all-pass filter" do
      q = Album.search(nil)
      expect(q.count).to eq Album.all.count
    end

  end

  describe "order" do
    it "can order when passed an array" do
      q = Album.order("Name ASC")
      expect(q.first.name).to eq "A Swingin' Affair"
      q = Album.order("Name")
      expect(q.first.name).to eq "A Swingin' Affair"
      q = Album.order("Name DESC")
      expect(q.first.name).to eq "Voodoo"
    end
  end

end
