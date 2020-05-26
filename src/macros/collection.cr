module Hathor
  module CollectionMacro
    # collection macro
    # * it populates the PROPERTIES hash
    # * creates property name : Array(type | Nil) - Nil only if nilable
    macro collection(collection_name, **options)
      {%
        raise "#{collection_name} must not be a type decolration" if collection_name.is_a? TypeDeclaration
        raise "#{collection_name} must define \"of\"-option" unless options[:of]
        name = collection_name.id

        # register name and type in contract class config
        PROPERTIES[name] = options || {} of Nil => Nil
        PROPERTIES[name][:type] = :array
        PROPERTIES[name][:inner_type] = options[:of]
        PROPERTIES[name][:nilable] = options[:nilable].is_a?(BoolLiteral) ? options[:nilable] : true
      %}

      # create property of nested class type
      {% if PROPERTIES[name][:nilable] %}
        property {{name}} : Array({{options[:of].id}}) | Nil
      {% else %}
        property {{name}} : Array({{options[:of].id}}) = [] of {{options[:of].id}}
      {% end %}
    end

    # shortcut for "nilable: false" option
    macro collection!(name, **options)
      collection({{name}}, nilable: false, {{**options}})
    end

  end
end