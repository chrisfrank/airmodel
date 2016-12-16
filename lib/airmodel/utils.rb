module Airmodel
  module Utils

    def table_name
      @table_name || self.name.tableize.to_sym
    end

    def base_config
      if @base_id
        { :base_id => @base_id, :table_name => table_name }
      else
        Airmodel.bases[table_name] || raise(NoSuchBase.new("Could not find base '#{table_name}' in config file"))
      end
    end
    #
    # return an Airtable::Table object,
    # backed by a base defined in DB YAML file
    def table
      Airmodel.client.table base_config[:base_id], base_config[:table_name]
    end

    def at(base_id, table_name)
      Airmodel.client.table(base_id, table_name)
    end

    ## converts array of generic airtable records to the instances
    # of the appropriate class
    def classify(obj=[])
      if obj.is_a? Airtable::Record
        [self.new(obj.fields)]
      elsif obj.respond_to? :map
        obj.map{|r| self.new(r.fields) }
      else
        raise AlienObject.new("Object is neither an array nor an Airtable::Model")
      end
    end

    # convert blank strings to nil, [""] to [], and "true" to a boolean
    def airtable_formatted(hash)
      h = hash.dup
      h.each{|k,v|
        if v == [""]
          h[k] = []
        elsif v == ""
          h[k] = nil
        elsif v == "true"
          h[k] = true
        elsif v == "false"
          h[k] = false
        end
      }
    end

    # Returns a hash that removes any matches with the other hash
    #
    # {a: {b:"c"}} - {:a=>{:b=>"c"}}                   # => {}
    # {a: [{c:"d"},{b:"c"}]} - {:a => [{c:"d"}, {b:"d"}]} # => {:a=>[{:b=>"c"}]}
    #
    def hash_diff!(first_hash, second_hash)
      second_hash.each_pair do |k,v|
        tv = first_hash[k]
        if tv.is_a?(Hash) && v.is_a?(Hash) && v.present? && tv.present?
          tv.diff!(v)
        elsif v.is_a?(Array) && tv.is_a?(Array) && v.present? && tv.present?
          v.each_with_index do |x, i| 
            tv[i].diff!(x)
          end
          first_hash[k] = tv - [{}]
        else
          first_hash.delete(k) if first_hash.has_key?(k) && tv == v
        end
        first_hash.delete(k) if first_hash.has_key?(k) && first_hash[k].blank?
      end
      first_hash
    end

    def hash_diff(first_hash, second_hash)
      hash_diff!(first_hash.dup, second_hash)
    end

    def -(first_hash, second_hash)
      hash_diff(first_hash, second_hash)
    end

    class AlienObject < StandardError
    end

  end
end
