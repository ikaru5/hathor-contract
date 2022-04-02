require "json"
require "log"
require "./validation"
require "./macros/*"

module Hathor
  class Contract
    include Hathor::CollectionMacro
    include Hathor::NestedCollectionMacro
    include Hathor::NestedMacro
    include Hathor::NestedContractMacro
    include Hathor::FieldMacro
    include Hathor::Validation

    # inherited hook will run on AST entry (the very first thing of macros)
    macro inherited
      # all fields will be created as basic crystal properties like this: property name : (String | Nil)
      # The following hash PROPERTIES saves all information about the fields and given options.
      # So its the "contract class config".
      # This variable is available during AST node parsing.
      # Thanks to inherited hook it is @type.id class related and not super class.
      PROPERTIES = {} of Nil => Nil

      # validates and vaalidates_elements_of macros run at the same level as as field, nested,... etc.
      # so its impossible to control the sequence
      # instead just save them in this hash and merge them in final proccess hook
      OUTER_VALIDATES = {} of Nil => Nil
      
      # defined by user through validate macro and maybe later for inline validations per field 
      CUSTOM_VALIDATIONS = {} of Nil => Nil

      # Finished hook is the last thing of AST node parsing.
      # By putting it inside inherited macro, we ensure that it will be run after simple macros are over and
      # only for the @type.id class. So this is THE REALLY LAST THING OF AST.
      macro finished
        __process
      end
    end

    def self.log_invalid_type(field_name : String, provided_type : String, field_kind = "field")
      Log.info { "#{self.class.to_s} Invalid type at #{field_kind}: #{field_name} provided type: #{provided_type}" }
    end

    # things that have to be done at the end of AST, after field macro populated PROPERTIES-Hash
    macro __process
      __process_validation

      # class method for init from hash
      # note: a lot of lines are written too redundant, but it pushes the maintainability :)
      # returns new instance populated from given hash or JSON::Any hash
      def self.from_hash(hash, decorate_json_style : Bool = false)
        instance = self.new
        # need to cast JSON:Any values to their basic types
        {%
          translate = {
            Bool: "as_bool", String: "as_s",
            Float64: "as_f", Float32: "as_f32",
            Int32: "as_i", Int64: "as_i64",
          }
        %}
        {% for field_name, options in PROPERTIES %}
          # extract value by field name
          key_string = decorate_json_style ? "{{field_name.id.camelcase lower: true}}" : "{{field_name.id}}"
          key_symbol = decorate_json_style ? :{{field_name.id.camelcase lower: true}} : :{{field_name.id}}
          value = hash[key_string]? || hash[key_symbol]?

          unless value.is_a?(Nil)
            # nested elements are contracts themself, so they can handle the hashed value on their own
            {% if [:nested, :nested_contract].includes? options[:type] %}
              if value.is_a?(Hash)
                instance.{{field_name.id}} = instance.{{field_name.id}} = {{options[:nested_class].id}}.from_hash value, decorate_json_style: decorate_json_style
              elsif value.is_a?(JSON::Any)
                instance.{{field_name.id}} = instance.{{field_name.id}} = {{options[:nested_class].id}}.from_hash value.as_h, decorate_json_style: decorate_json_style
              else
                log_invalid_type("{{field_name.id}}", value.class.to_s, "{{options[:type].id}}")
              end
            # collections are properies of typed arrays like field : Array(T)
            {% elsif [:array, :array_of_contracts].includes? options[:type] %}
              # if according array is provided, we can simply assign it
              if value.is_a?(Array({{options[:inner_type].id}}))
                instance.{{field_name.id}} = value
              else
                # if type doesnt fit, like Array(JSON::Any), we need to create empty array at property and add the values accordingly
                instance.{{field_name.id}} = [] of {{options[:inner_type].id}}
                if value.is_a?(Array) || value.is_a?(JSON::Any) # check if array to be able to iterate with "each"
                  (value.is_a?(JSON::Any) ? value.as_a : value).each do |element|
                    {% if :array == options[:type] %}
                      # if elements of type JSON::Any, they need to be casted to the proper type
                      if element.is_a?(JSON::Any)
                        instance.{{field_name.id}}.not_nil! << element.{{translate[options[:inner_type].id].id}}
                      elsif element.is_a?({{options[:inner_type].id}})
                        instance.{{field_name.id}}.not_nil! << element
                      else
                        log_invalid_type("{{field_name.id}}", element.class.to_s, "collection")
                      end
                    {% else %}
                      # if element is a nested_collection, it is a array of contracts, so like on nested fields we can simply let the nested contracts handle the elements
                      if element.is_a?(Hash)
                        instance.{{field_name.id}}.not_nil! <<
                          {{options[:inner_type].id}}.from_hash(element, decorate_json_style: decorate_json_style)
                      elsif element.is_a?(JSON::Any)
                        instance.{{field_name.id}}.not_nil! <<
                          {{options[:inner_type].id}}.from_hash(element.as_h, decorate_json_style: decorate_json_style)
                      else
                        log_invalid_type("{{field_name.id}}", element.class.to_s, "nested_collection")
                      end
                    {% end %}
                  end
                end
              end
            {% else %}
              # Special Case: a simple field is a string with json_string: true optione -> the dev wants the nested information be json
              {% if options[:json_string] && "String" == options[:type].id %}
                instance.{{field_name.id}} = value.to_json
              {% else %}
                # if its a simple field and type is JSON::Any we translate it and in case it fits we can simply assign it
                # if it doesnt fit do not assign
                if value.is_a?({{options[:type].id}})
                  instance.{{field_name.id}} = value
                elsif value.is_a?(JSON::Any)
                  instance.{{field_name.id}} = value.{{translate[options[:type].id].id}} unless value.raw.nil?
                else
                  puts "TODO: remove me after log finished: log_invalid_type {{field_name.id}}"
                  log_invalid_type("{{field_name.id}}", value.class.to_s, "field")
                end
              {% end %}

            {% end %}
          end
        {% end %}
        instance
      end

      # build and returns hash with currently assigned values
      # also used for json construction, so needs to decorate the field names
      def to_hash(decorate_json_style : Bool = false)
        {% if 0 < PROPERTIES.size %}
          {%
            command = "{"
            command_decorated = "{ "
          %}
          {% for field_name, options, index in PROPERTIES %}
            {% field_name_decorated = field_name.id.camelcase lower: true %}
            {% if [:nested, :nested_contract].includes? options[:type] %}
              {%
                formatted_value = "#{field_name.id}.nil? ? nil : #{field_name.id}.not_nil!.to_hash(decorate_json_style: decorate_json_style)"
              %}
            {% elsif [:array_of_contracts].includes? options[:type] %}
              {%
                formatted_value = "#{field_name.id}.nil? ? nil : #{field_name.id}.not_nil!.map(&.to_hash(decorate_json_style: decorate_json_style))"
              %}
            {% elsif options[:json_string] && "String" == options[:type].id %}
              {%
                formatted_value = "#{field_name.id}.empty? ? \"\" : JSON.parse(#{field_name.id})"
              %}
            {% else %}
              {%
                formatted_value = "#{field_name.id}"
              %}
            {% end %}
            {%
              command = "#{command.id}\n :#{field_name.id} => #{formatted_value.id}"
              command_decorated = "#{command_decorated.id}\n :#{field_name_decorated.id} => #{formatted_value.id}"
              unless PROPERTIES.size - 1 == index
                command = "#{command.id},"
                command_decorated = "#{command_decorated.id},"
              end
            %}
          {% end %}
          {%
            command = "#{command.id}\n}"
            command_decorated = "#{command_decorated.id}\n}"
          %}
          if decorate_json_style
            {{command_decorated.id}}
          else
            {{command.id}}
          end
        {% end %}
      end

      def to_json(decorate : Bool = true)
        to_hash(decorate_json_style: decorate).to_json
      end

      def self.from_json(json_string : String, decorate : Bool = true)
        hash = JSON.parse(json_string).as_h
        self.from_hash(hash, decorate_json_style: decorate)
      end
    end

  end
end