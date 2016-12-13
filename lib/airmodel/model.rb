module Airmodel
  class Model < Airtable::Record
    extend Utils

    # returns all records in a table, making as many calls as necessary
    # to work around Airtable's 100-record per page design. This can be VERY
    # slow, and should not be used in production unless you cache it agressively.
    # Where possible, use Model.some instead.
    def self.all(args={sort: default_sort})
      puts "RUNNING EXPENSIVE API QUERY TO AIRTABLE (#{self.name})"
      self.classify table.all(args)
    end

    # returns up to 100 records from Airtable
    def self.some(args={sort: default_sort})
      puts "RUNNING EXPENSIVE API QUERY TO AIRTABLE (#{self.name})"
      self.classify table.records(args)
    end

    # find up to 100 records that match the filters
    def self.where(filters)
      order = filters.delete(:sort)
      formula = "AND(" + filters.map{|k,v| "{#{k}}='#{v}'" }.join(',') + ")"
      some(
        sort: order,
        filterByFormula: formula,
      )
    end

    # find a record by ID.
    # IF you've (1) defined an 'id' Field in Airtable, (2) made it a formula,
    # and (3) set the formula to RECORD_ID(),
    # THEN you can pass self.find([an,array,of,ids]) and it will return
    # each record in that order. This is mostly only useful for looking up
    # records linked to a particular record.
    def self.find(id)
      if id.is_a? String
        results = self.classify table.find(id)
        results.count == 0 ? nil : results.first
      else
        formula = "OR(" + id.map{|x| "id='#{x}'" }.join(',') + ")"
        some(filterByFormula: formula).sort_by do |x|
          id.index(x.id)
        end
      end
    end

    # find a record by specified attributes, return it
    def self.find_by(filters)
      if filters[:id]
        results = self.classify table.find(filters[:id])
      else
        formula = "AND(" + filters.map{|k,v| "{#{k}}='#{v}'" }.join(',') + ")"
        results = some(
          filterByFormula: formula,
          limit: 1
        )
      end
      results.count == 0 ? nil : results.first
    end

    # default to whatever order Airtable returns
    # override this method if you want to sort by something else
    def self.default_sort
      nil
    end

    # return the first record
    def self.first
      results = some(
        limit: 1
      )
      results.count == 0 ? nil : results.first
    end

    # create a new record and save it to Airtable
    def self.create(*models)
      results = models.map{|r|
        record = self.new(r)
        table.create(record)
      }
      results.length == 1 ? results.first : results
    end

    # send a PATCH request to update a few fields on a record in one API call
    def self.patch(id, fields)
      r = table.update_record_fields(id, airtable_formatted(fields))
      self.new(r.fields)
    end

    # INSTANCE METHODS

    # return self.class.table. defined as an instance
    # method to allow individual models to override it and
    # connect to a different base in strange circumstances.
    def table
      self.class.table
    end

    def formatted_fields
      self.class.airtable_formatted(self.fields)
    end

    def save
      if self.valid?
        if new_record?
          self.table.create(self)
        else
          result = self.table.update_record_fields(id, self.changed_fields)
          result
        end
      else
        false
      end
    end

    def changed_fields
      current = fields
      old = self.class.find_by(id: id).fields
      self.class.hash_diff(current, old)
    end

    def destroy
      self.table.destroy(id)
    end

    def update(fields)
      res = self.table.update_record_fields(id, fields)
      res.fields.each{|field, value| self[field] = value }
      self
    end

    def new_record?
      id.nil?
    end

    def cache_key
      "#{self.class.table_name}_#{self.id}"
    end

    # override if you want to write server-side model validations
    def valid?
      true
    end

    # override if you want to return validation errors
    def errors
      {}
    end

  end

  # raise this error when a table
  # is not defined in config/airtable_data.yml
  class NoSuchBase < StandardError
  end

  class NoConnection < StandardError
  end

end
