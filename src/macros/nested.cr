module Hathor
  module NestedMacro
    # nested macro
    # To achieve nesting like contract.address.street, we think about the nested element as a new nested contract.
    # * populates the PROPERTIES hash to a nested element
    # * defines @type.id::nested_name < Contract class with yield
    # * depending on nilable option
    #   * casts property name : @type.id::nested_name | Nil
    #     * defines new_@type.id::nested_name method
    #   * casts property name : @type.id::nested_name
    macro nested(nested_name, **options)
      {%
        # register name and type in class config
        name = nested_name.id
        PROPERTIES[name] = options || {} of Nil => Nil
        PROPERTIES[name][:type] = :nested
        nested_class = "::#{@type.id}::#{name.camelcase}"
        PROPERTIES[name][:nested_class] = nested_class
        PROPERTIES[name][:nilable] = options[:nilable].is_a?(BoolLiteral) ? options[:nilable] : true
      %}
      # create new nested class
      class {{nested_class.id}} < Hathor::Contract # todo: base class
        {{ yield.id }}
      end

      # create property of nested class type
      {% if PROPERTIES[name][:nilable] %}
        property {{name}} : ({{nested_class.id}} | Nil)

        # define a "new_name_of_field" helper method
        def new_{{name}}
          self.{{name}} = {{nested_class.id}}.new
        end
      {% else %}
        property {{name}} : {{nested_class.id}} = {{nested_class.id}}.new
      {% end %}
    end

    # shortcut for "nilable: false" option
    macro nested!(name, **options)
      nested({{name}}, nilable: false, {{**options}}) do
        {{ yield.id }}
      end
    end

  end
end