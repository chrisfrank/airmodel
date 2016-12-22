require 'spec_helper'

class Song < Airmodel::Model
end

class Album < Airmodel::Model
end

class ParentModel < Airmodel::Model
  has_many :songs

  def dynamically_assigned_child_base_id
    "appTE8VIb595FI4c6"
  end

end

describe ParentModel do

  describe 'has_many' do
    it 'should return a list of songs' do
      songs = ParentModel.new.songs
      expect(songs.first.is_a? Song).to be true
    end

    it "Should look in the parent model's base when not passed a base_key" do
      Song.has_many :albums
      albums = Song.first.albums.all
      expect(albums.first.name).to eq "Blood on the Tracks"
    end

    it 'should raise NoSuchBase when passed a weird association not backed by bases.yml' do
      begin
        ParentModel.has_many :unusual_children
        ParentModel.new.unusual_children
        expect(true).to eq false
      rescue Airmodel::NoSuchBase
        true
      end
    end

    it 'should work when passed a weird association that *is* backed by bases.yml' do
      ParentModel.has_many :tracks, class_name: 'Song'
    end

    it 'should work with a base_key instead of a yml file' do
      ParentModel.has_many :tunes, base_key: 'dynamically_assigned_child_base_id', class_name: 'Song', table_name: "Songs"
      tunes = ParentModel.new.tunes
      expect(tunes.first.table.worksheet_name).to eq "Songs"
    end

    it 'should let me define the important args however I like'

  end

end


