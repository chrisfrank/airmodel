module Airmodel
  class Model < Airtable::Record

    def self.table_name
      self.name.tableize.to_sym
    end

    # return an array of Airtable::Table objects,
    # each backed by a base defined in DB YAML file
    def self.tables(args={})
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

    def self.at(base_id, table_name)
      Airmodel.client.table(base_id, table_name)
    end

    ## converts array of generic airtable records to the instances
    # of the appropriate class
    def self.classify(list=[])
      list.map{|r| self.new(r.fields) }
    end

    # returns all records in the database, making as many calls as necessary
    # to work around Airtable's 100-record per page design
    def self.all(args={sort: default_sort})
      puts "RUNNING EXPENSIVE API QUERY TO AIRTABLE (#{self.name})"
      self.classify tables(args).map{|tbl| tbl.all(args)}.flatten
    end

    # returns up to 100 records from Airtable
    def self.records(args={sort: default_sort})
      puts "RUNNING EXPENSIVE API QUERY TO AIRTABLE (#{self.name})"
      self.classify tables(args).map{|tbl| tbl.records(args) }.flatten
    end

    # default to whatever order airtable returns
    # this method gets overridden on Airtabled classes
    def self.default_sort
      nil
    end

    # find records that match the filters
    def self.where(filters)
      shard = filters.delete(:shard)
      order = filters.delete(:sort)
      formula = "AND(" + filters.map{|k,v| "{#{k}}='#{v}'" }.join(',') + ")"
      records(
        shard: shard,
        sort: order,
        filterByFormula: formula,
      )
    end

    # find a record by specified attributes, return it
    def self.find_by(filters)
      shard = filters.delete(:shard)
      if filters[:id]
        results = self.classify tables(shard: shard).map{|tbl| tbl.find(filters[:id]) }
      else
        formula = "AND(" + filters.map{|k,v| "{#{k}}='#{v}'" }.join(',') + ")"
        results = records(
          shard: shard,
          filterByFormula: formula,
          limit: 1
        )
      end
      results.count == 0 ? nil : results.first
    end

    # return the first record
    def self.first
      results = records(
        limit: 1
      )
      results.count == 0 ? nil : results.first
    end

    # create a new record and save it to Airtable
    def self.create(*records)
      results = records.map{|r|
        record = self.new(r)
        tables.map{|tbl| tbl.create(record) }.first
      }
      results.length == 1 ? results.first : results
    end

    # send a PATCH request to update a few fields on a record in one API call
    def self.patch(id, fields, shard=nil)
      r = tables(shard: shard).map{|tbl|
        tbl.update_record_fields(id, airtable_formatted(fields))
      }.first
      self.new(r.fields)
    end

    # convert blank strings to nil, [""] to [], and "true" to a boolean
    def self.airtable_formatted(hash)
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
    def self.normalized_base_config(config)
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

    # INSTANCE METHODS

    def formatted_fields
      self.class.airtable_formatted(self.fields)
    end

    def save(shard=self.shard_identifier)
      if self.valid?
        if new_record?
          results = self.class.tables(shard: shard).map{|tbl|
            tbl.create self
          }
          # return the first version of this record that saved successfully
          results.find{|x| !!x }
        else
          self.class.tables(shard: shard).map{|tbl|
            tbl.update_record_fields(id, self.changed_fields)
          }
        end
      else
        false
      end
    end

    def changed_fields
      current = fields
      old = self.class.find_by(id: id, shard: shard_identifier).fields
      current.diff(old)
    end

    def destroy
      self.class.tables(shard: shard_identifier).map{|tbl| tbl.destroy(id) }
    end

    def update(fields)
      self.class.tables(shard: shard_identifier).map{|tbl| tbl.update_record_fields(id, fields) }
    end

    def new_record?
      id.nil?
    end

    def cache_key
      "#{self.class.name.tableize}_#{self.id}"
    end

    def valid?
      true
    end

    def errors
      {}
    end

    def shard_identifier
      nil
    end

  end

  # raise this error when a table
  # is not defined in config/airtable_data.yml
  class NoSuchBase < StandardError
  end

  class NoConnection < StandardError
  end

end
