module Airmodel
  module Associable

    # defines a clone of the child class on this model
    # required args: association_name
    def has_many(association_name, args={})
      args[:class_name] ||= association_name.to_s.singularize.capitalize
      define_method association_name do
        config = if args[:base_key]
                   # the airtable base_id is dynamically configured
                   # as a column on the parent model,
                   # and the table_name is either passed as
                   # an argument or inferrred from the child model name
                   {
                     base_id: self.send(args[:base_key]),
                     table_name: args[:table_name] || association_name.to_s.tableize
                   }
                   # maybe the base is defined in the config file
                 elsif c = Airmodel.bases[args[:class_name].tableize.to_sym]
                   c
                # maybe the base is just a table in the same base as the parent
                 else
                   {
                     base_id: self.class.base_config[:base_id],
                     table_name: args[:table_name] || association_name.to_s.tableize
                   }
                 end
        finder_name = "@#{association_name}_finder"
        if f = instance_variable_get(finder_name)
          f
        else
          finder = Class.new(Object.const_get args[:class_name]) do
            @base_id = config[:base_id]
            @table_name = config[:table_name]
          end
          constraints = if args[:constraints].respond_to?(:call)
                          args[:constraints].call(self)
                        else
                          {}
                        end
          instance_variable_set(finder_name, finder.where(constraints))
        end
      end
    end

    def default_has_many_contraints
      true
    end

  end
end
