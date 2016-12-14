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
                 else
                   # the airtable base info is defined in the
                   # YML config file, with the rest of the data
                   Airmodel.bases[args[:class_name].tableize.to_sym] || raise(NoSuchBase.new("Couldn't find base '#{association_name}' in config file.\nPlease pass :base_key => foo with your has_many call,\nor add '#{association_name}' to your config file."))
                 end
        finder_name = "@#{association_name}_finder"
        if f = instance_variable_get(finder_name)
          f
        else
          finder = Class.new(Object.const_get args[:class_name]) do
            @base_id = config[:base_id]
            @table_name = config[:table_name]
          end
          instance_variable_set(finder_name, finder)
        end
      end
    end

  end
end
