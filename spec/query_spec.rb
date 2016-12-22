require "spec_helper"

class Album < Airmodel::Model
end

describe Album do

    describe "where" do
      it "allows chaining" do
        q = Album.where(
          "name" => "Tidal",
          "artist" => "Fiona Apple"
        ).limit(10)
        expect(q.class).to eq Airmodel::Query
        # it should execute the query on
        # query.all, and return an array
        expect(q.all.class).to be Array
      end

      it "can replace where_clauses with a raw airtable formula" do
        formula = "NOT({Rating} < 4"
        q = Album.where("great" => true).by_formula(formula)
        expect(q.params[:where_clauses]).to be {}
        expect(q.params[:formula]).to be formula
        expect(q.all.class).to be Array
      end
    end

    describe "limit", skip_before: true do
      it "limits the results to the specified number" do
        q = Album.limit(1).all
        expect(q.count).to eq 1
      end
    end

end
