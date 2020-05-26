module Hathor
  module NestedContractMacro
    # nested_contract macro allows to define properties of type of other contracts
    # Technically its a hybrid of nested and field macro.
    # Its the same as nested, but doesnt need an inline class.
    macro nested_contract(type_declaration, **options)
      {%
        raise "#{type_declaration} is not a TypeDeclaration" unless type_declaration.is_a? TypeDeclaration

        # extract name and type for property
        name = type_declaration.var.id
        type = type_declaration.type

        # register name and type in contract class config
        PROPERTIES[name] = options || {} of Nil => Nil
        PROPERTIES[name][:type] = :nested_contract
        PROPERTIES[name][:nested_class] = type
        PROPERTIES[name][:nilable] = options[:nilable].is_a?(BoolLiteral) ? options[:nilable] : true
      %}

      # create property of nested class type
      {% if PROPERTIES[name][:nilable] %}
        property {{name}} : ({{type}} | Nil)
      {% else %}
        property {{name}} : {{type}} = {{PROPERTIES[name][:nested_class].id}}.new
      {% end %}
    end

    # shortcut for "nilable: false" option
    macro nested_contract!(type_declaration, **options)
      nested_contract({{type_declaration}}, nilable: false, {{**options}})
    end

  end
end