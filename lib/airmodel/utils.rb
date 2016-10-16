module Airmodel
  module Utils

    def table_name
      self.name.tableize.to_sym
    end
    #
    # return an array of Airtable::Table objects,
    # each backed by a base defined in DB YAML file
    def tables(args={})
      db = Airmodel.bases[table_name] || raise(NoSuchBase.new("Could not find base '#{table_name}' in config file"))
      bases = normalized_base_config(db[:bases])
      # return just one Airtable::Table if a particular shard was requested
      if args[:shard]
        [Airmodel.client.table(bases[args.delete(:shard)], db[:table_name])]
      # otherwise return each one
      else
        bases.map{|key, val| Airmodel.client.table val, db[:table_name] }
      end
    end

    def at(base_id, table_name)
      Airmodel.client.table(base_id, table_name)
    end

    ## converts array of generic airtable records to the instances
    # of the appropriate class
    def classify(list=[])
      list.map{|r| self.new(r.fields) }
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

    # standardizes bases from config file, whether you've defined
    # your bases as a single string, a hash, an array,
    # or an array of hashes, returns hash of form { "base_label" => "base_id" }
    def normalized_base_config(config)
      if config.is_a? String
        { "#{config}" => config }
      elsif config.is_a? Array
        parsed = config.map{|x|
          if x.respond_to? :keys
            [x.keys.first, x.values.first]
          else
            [x,x]
          end
        }
        Hash[parsed]
      else
        config
      end
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
  end
end
