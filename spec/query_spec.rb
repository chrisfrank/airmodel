require "spec_helper"

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
  end

  after(:each) do
    FakeWeb.clean_registry
  end


  describe "where" do
    it "allows chaining" do
      q = Album.where(
        "name" => "Tidal",
        "artist" => "Fiona Apple",
        "great" => true
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

end

