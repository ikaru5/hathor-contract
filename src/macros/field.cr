module Hathor
  module FieldMacro
    # field macro
    # * it populates the PROPERTIES hash
    # * creates property name : type | Nil
    macro field(type_declaration, **options)
      {%
        raise "#{type_declaration} is not a TypeDeclaration" unless type_declaration.is_a? TypeDeclaration

        # extract name and type for property
        name = type_declaration.var.id
        type = type_declaration.type

        # register name and type in contract class config
        PROPERTIES[name] = options || {} of Nil => Nil
        PROPERTIES[name][:type] = type
        PROPERTIES[name][:nilable] = options[:nilable].is_a?(BoolLiteral) ? options[:nilable] : true
      %}

      {% default = options[:default] if options[:default] %}
      {%
        # TODO: should be overwritable
        defaults_for_type = {
          Bool: "false", String: "\"\"",
          Float64: "-1", Float32: "-1",
          Int32: "-1", Int64: "-1",
          "JSON::Any": "JSON.parse(\"{}\")"
        }
      %}
      # create property of nested class type
      {% if PROPERTIES[name][:nilable] %}
        {% command = "property #{name} : (#{type.id} | Nil)" %}
        {% command = "#{command.id} = #{options[:default]}" if options[:default] %}
      {% else %}
        {% command = "property #{name} : (#{type.id})" %}
        {% command = options[:default] ? "#{command.id} = #{options[:default]}" : "#{command.id} = #{defaults_for_type[options[:type].id].id}" %}
      {% end %}
      {{command.id}}
    end

    # shortcut for "nilable: false" option
    # USE WITH CAUTION! Contract will not parse if field is missing!
    macro field!(type_declaration, **options)
      field({{type_declaration}}, nilable: false, {{**options}})
    end

  end
end