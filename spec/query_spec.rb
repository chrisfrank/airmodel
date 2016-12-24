require "spec_helper"

class Album < Airmodel::Model
end

describe Album do

    describe "where" do
      it "allows chaining" do
        q = Album.where(
          "name" => "Tidal",
          "artist" => "Fiona Apple"
        ).limit(10).order("Name", "desc")
        expect(q.class).to eq Airmodel::Query
        # it should execute the query on
        # query.all, and return an array
        expect(q.all.class).to be Array
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
    end

    describe "search" do
      it "searches in args[:field] for args[:value]" do
        q = Album.search(q: "Fiona", field: "Artist")
        expect(q.count).to eq 1
        expect(q.first.artist).to eq "Fiona Apple"
      end
    end

end
