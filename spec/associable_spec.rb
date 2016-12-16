require 'spec_helper'

class Song < Airmodel::Model
end

class ParentModel < Airmodel::Model
  has_many :songs

  def dynamically_assigned_child_base_id
    'appABCDEF'
  end
end

describe ParentModel do

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


  describe 'has_many' do
    it 'should return a list of songs' do
      songs = ParentModel.new.songs
      expect(songs.table_name).to eq 'songs'
    end

    it 'should raise NoSuchBase when passed a weird association not backed by bases.yml' do
      begin
        ParentModel.has_many :unusual_children
        false
      rescue Airmodel::NoSuchBase
        true
      end
    end

    it 'should work when passed a weird association that *is* backed by bases.yml' do
      ParentModel.has_many :tracks, class_name: 'Song'
    end

    it 'should work with a base_key instead of a yml file' do
      stub_airtable_response!(
        Regexp.new("https://api.airtable.com/v0/appABCDEF/tunes"),
        { "records" => [{"id": "recXYZ", fields: {"color":"red"} }, {"id":"recABC", fields: {"color": "blue"} }] }
      )
      ParentModel.has_many :tunes, base_key: 'dynamically_assigned_child_base_id', class_name: 'Song'
      tunes = ParentModel.new.tunes
      expect(tunes.first.table.worksheet_name).to eq 'tunes'
    end

    it 'should let me define the important args however I like'

  end

end


