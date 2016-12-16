module Airmodel
  class Query

    def initialize(querying_class)
      @querying_class = querying_class
    end

    def params
      @params ||= {
        filters: {},
        order: @querying_class.default_sort
      }
    end

    def where(args)
      params[:filters].merge!(args)
      self
    end

    def limit(lim)
      params[:limit] = lim
      self
    end

    def order(column, direction)
      params[:order] = [column, direction]
      self
    end

    # add kicker methods
    def to_a
      puts "RUNNING EXPENSIVE API QUERY TO AIRTABLE (#{@querying_class.name})"
      formula = "AND(" + params[:filters].map{|k,v| "{#{k}}='#{v}'" }.join(',') + ")"
      @querying_class.classify @querying_class.table.all(
        sort: params[:order],
        filterByFormula: formula,
        limit: params[:limit]
      )
    end

    def all
      to_a
    end

    def first
      to_a.first
    end

    def last
      to_a.last
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

  end
end

