module Airmodel
  class Model < Airtable::Record

    def self.client
      Airmodel::Bases.client
    end

    # return an array of Airtable::Table objects,
    # each backed by a base defined in DB yaml file
    def self.tables(args={})
      db = Airmodel::Bases.load[self.name.tableize.to_sym] || raise(NoSuchBase)
      if db[:shards]
        if args[:shard] && db[:shards][args[:shard]]
          [client.table(db[:shards][args.delete(:shard)], db[:table_name])]
        else
          db[:shards].map{|key,val| client.table val, db[:table_name]}
        end
      else
        [client.table(db[:base_id], db[:table_name])]
      end
    end

    def self.at(base_id, table_name)
      client.table(base_id, table_name)
    end

    ## converts array of generic airtable records to the instances
    # of the appropriate class
    def self.classify(records=[])
      records.map{|r| self.new(r.fields) }
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
