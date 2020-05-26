module Hathor
  module NestedCollectionMacro
    # collection macro
    # * it populates the PROPERTIES hash
    # * creates property name : Array(type | Nil) - Nil only if nilable
    macro nested_collection(collection_name, **options, &block)
      {%
        has_block = yield.id != ""
        raise "#{collection_name} must not be a type decolration" if collection_name.is_a? TypeDeclaration
        raise "#{collection_name} must define an \"of\"-option or a block" if !options[:of] && !has_block
        name = collection_name.id

        # register name and type in contract class config
        PROPERTIES[name] = options || {} of Nil => Nil
        PROPERTIES[name][:type] = :array_of_contracts
        inner_class = options[:of] || "#{@type.id}::#{name.camelcase}"
        PROPERTIES[name][:inner_type] = inner_class
        PROPERTIES[name][:nilable] = options[:nilable].is_a?(BoolLiteral) ? options[:nilable] : true
      %}

      # create new nested class
      {% if has_block %}
        class {{inner_class.id}} < Hathor::Contract # todo base class
          {{ yield }}
        end
      {% end %}

      # create property of nested class type
      {% if PROPERTIES[name][:nilable] %}
        property {{name}} : Array({{inner_class.id}}) | Nil
        # define a "new_name_of_field" helper method
        def new_{{name}}
          self.{{name}} = Array({{inner_class.id}}).new
        end
      {% else %}
        property {{name}} : Array({{inner_class.id}}) = [] of {{inner_class.id}}
      {% end %}

      # define a "populate_name_of_field" helper method
      def populate_{{name}}
        unless self.{{name}}.is_a? Nil
          self.{{name}}.not_nil! << {{inner_class.id}}.new
        end
      end
    end

    # shortcut for "nilable: false" option
    macro nested_collection!(name, **options)
      nested_collection({{name}}, nilable: false, {{**options}})
    end

  end
end