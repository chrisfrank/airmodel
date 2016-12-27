module Airmodel
  class Query
    include Enumerable

    def initialize(querying_class)
      @querying_class = querying_class
    end

    def params
      @params ||= {
        where_clauses: {},
        formulas: [],
        order: @querying_class.default_sort,
        offset: nil
      }
    end

    def where(args)
      params[:where_clauses].merge!(args)
      self
    end

    def by_formula(formula)
      params[:formulas].push formula
      self
    end

    def search(args={})
      if args && args[:q] && args[:fields]
        searchfields = if args[:fields].is_a?(String)
                        args[:fields].split(",").map{|f| f.strip }
                       else
                         args[:fields]
                       end
        query = if args[:q].respond_to?(:downcase)
                  args[:q].downcase
                else
                  args[:q]
                end
        f = "OR(" + searchfields.map{|field|
          # convert strings to case-insensitive searches
          "FIND('#{query}', LOWER({#{field}}))"
        }.join(',') + ")"
        params[:formulas].push f
      end
      self
    end

    def limit(lim)
      params[:limit] = lim ? lim.to_i : nil
      self
    end

    def order(order_string)
      if order_string
        ordr = order_string.split(" ")
        column = ordr.first
        direction = ordr.length > 1 ? ordr.last.downcase : "asc"
        params[:order] = [column, direction]
      end
      self
    end


    def offset(airtable_offset_key)
      params[:offset] = airtable_offset_key
      self
    end

    # return saved airtable offset for this query
    def get_offset
      @offset
    end

    # add kicker methods
    def to_a
      puts "RUNNING EXPENSIVE API QUERY TO AIRTABLE (#{@querying_class.name})"
      # merge explicit formulas and abstracted where-clauses into one Airtable Formula
      formula = "AND(" + params[:where_clauses].map{|k,v| "{#{k}}='#{v}'" }.join(',') + params[:formulas].join(',') + ")"
      records = @querying_class.table.records(
        sort: params[:order],
        filterByFormula: formula,
        limit: params[:limit],
        offset: params[:offset]
      )
      @offset = records.offset
      @querying_class.classify records
    end

    def all
      to_a
    end

    def each(&block)
      to_a.each(&block)
    end

    def map(&block)
      to_a.map(&block)
    end

    def inspect
      to_a.inspect
    end

    def last
      to_a.last
    end

    def find_by(filters)
      params[:limit] = 1
      params[:where_clauses] = filters
      first
    end

  end
end

