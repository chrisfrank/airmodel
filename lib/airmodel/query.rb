module Airmodel
  class Query
    include Enumerable

    def initialize(querying_class)
      @querying_class = querying_class
    end

    def params
      @params ||= {
        where_clauses: {},
        order: @querying_class.default_sort
      }
    end

    def where(args)
      params[:where_clauses].merge!(args)
      self
    end

    def by_formula(formula)
      params[:where_clauses] = {}
      params[:formula] = formula
      self
    end

    def limit(lim)
      params[:limit] = lim
      self
    end

    def order(column, direction)
      params[:order] = [column, direction.downcase.to_sym]
      self
    end

    # add kicker methods
    def to_a
      puts "RUNNING EXPENSIVE API QUERY TO AIRTABLE (#{@querying_class.name})"
      # filter by explicit formula, or by joining all where_clasues together
      formula = params[:formula] || "AND(" + params[:where_clauses].map{|k,v| "{#{k}}='#{v}'" }.join(',') + ")"
      @querying_class.classify @querying_class.table.records(
        sort: params[:order],
        filterByFormula: formula,
        limit: params[:limit]
      )
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

