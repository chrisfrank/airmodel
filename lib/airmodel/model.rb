module Airmodel
  class Model < Airtable::Record
    extend Utils
    extend Associable

    def self.all
      Query.new(self).all
    end

    def self.where(args)
      Query.new(self).where(args)
    end

    def self.by_formula(args)
      Query.new(self).by_formula(args)
    end

    def self.order(args)
      Query.new(self).order(args)
    end

    def self.limit(args)
      Query.new(self).limit(args)
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
        self.classify(
          table.records(filterByFormula: formula).sort_by do |x|
            id.index(x.id)
          end
        )
      end
    end

    # find a record by specified attributes, return it
    def self.find_by(filters)
      if filters[:id]
        results = self.classify table.find(filters[:id])
      else
        formula = "AND(" + filters.map{|k,v| "{#{k}}='#{v}'" }.join(',') + ")"
        results = self.classify(
          table.records(
            filterByFormula: formula,
            limit: 1
          )
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
      Query.new(self).first
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
