require 'spec_helper'

describe Airmodel::Query do
  let(:qry) { Airmodel::Query.new }
  #describe 'where' do
    #it 'remembers filters in a CLAUSES hash' do
      #qry.where(:kind => 'interesting')
      #expect(qry.filters[:clauses]).to include :kind
    #end
    #it 'is chainable' do
      #qry.where(:intelligence => 'low', adult: true).where('meaning' => 'none')
      #expect(qry.filters[:clauses]).to include :intelligence
      #expect(qry.filters[:clauses]).to include 'meaning'
    #end
  #end
end

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


  describe 'where' do
    it 'allows chaining' do
      m = Album.where(
        'name' => 'Tidal',
        'artist' => 'Fiona Apple',
        'great' => true
      ).limit(10)
      binding.pry
    end
  end

end

