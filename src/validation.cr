require "./validators/*"
require "./breakers/*"

module Hathor
  module Validation

    #######################################################
    # VALIDATORS
    #######################################################

    # simple validations
    VALIDATORS = {} of Nil => Nil
    # validations wich will stop other validations on !success!, for example: 'allow_blank'
    BREAKER_VALIDATORS = {} of Nil => Nil

    # register a validator module
    # option - name of option used in validates
    # method - method defined in validator
    # key - error string to add if validation fails
    macro register_validation(option, method, key)
      {% VALIDATORS[option.id] = {} of Nil => Nil %}
      {% VALIDATORS[option.id][:method] = method %}
      {% VALIDATORS[option.id][:key] = key %}
    end

    # register a validator module as breaker
    # option - name of option used in validates
    # method - method defined in validator
    macro register_validation_breaker(option, method)
      {% BREAKER_VALIDATORS[option.id] = {} of Nil => Nil %}
      {% BREAKER_VALIDATORS[option.id][:method] = method %}
    end

    # include and register validators
    include PresenceValidator
    include AbsenceValidator
    include MinValidator
    include MaxValidator
    include EmailValidator

    include AllowBlankBreaker

    register_validation presence, validate_presence, "not_present"
    register_validation absence, validate_absence, "not_absent"
    register_validation min, validate_minimum, "lt_min"
    register_validation max, validate_maximum, "gt_max"
    register_validation email, validate_email, "invalid_email"
    
    register_validation_breaker allow_blank, break_on_absence

    #######################################################
    # MACROS
    #######################################################

    # TODO would be nice to check within macros if validations are applyable to field type
    macro validates(field_name, **validation_options)
      {% OUTER_VALIDATES[field_name.id] = OUTER_VALIDATES[field_name.id] || {} of Nil => Nil %}
      {% OUTER_VALIDATES[field_name.id][:validates] = validation_options %}
    end

    macro validates_elements_of(field_name, **validation_options)
      {% OUTER_VALIDATES[field_name.id] = OUTER_VALIDATES[field_name.id] || {} of Nil => Nil %}
      {% OUTER_VALIDATES[field_name.id][:validates_inner] = validation_options %}
    end

    macro validate
      {% CUSTOM_VALIDATIONS[:validate] = yield.id %}
    end

    #######################################################
    # THINGS THAT RUN LATE LIKE METHOD DEFNITIONS
    #######################################################

    macro __process_validation

      # merge OUTER_VALIDATES into PROPERTIES
      {% for field_name, options in OUTER_VALIDATES %}
        {% if PROPERTIES[field_name] %}
          {% if options[:validates] %}
            {% PROPERTIES[field_name][:validates] = options[:validates] %}
          {% end %}

          {% if options[:validates_inner] %}
            {% PROPERTIES[field_name][:validates_inner] = options[:validates_inner] %}
          {% end %}
        {% else %}
          _validation_log("Validations for undefined Property: {{field_name.id}}")
        {% end %}
      {% end %}

      # write log messages
      def _validation_log(message)
        Log.info { "#{self.class.to_s} #{message}" }
      end
      def self._validation_log(message)
        Log.info { "#{self.class.to_s} #{message}" }
      end

      property errors = {} of String => Array(String)

      # the beautiful way of asking
      def valid?
        validate!
      end

      # used for definition of validate! method
      # first checks the validation breakers, if one of them returns true, the validations will be skipped.
      #
      # iterates over all validation options, which are defined for the current field
      # checks if the options, has an corresponding VALIDATOR
      # if VALIDATOR was registred the validation method will be called with the value and defined options passed
      # if method returns false, the validation did not pass and the defined error key, will be added to field_errors
      # at the end it will check if there are collected field_errors and assign them to @errors property
      macro __validate_field(field_name, validations)
        should_break = false
        \{% for option_name, options_for_validator in validations %}
          \{% if nil != BREAKER_VALIDATORS[option_name.id] %}
            if \{{BREAKER_VALIDATORS[option_name.id][:method]}}(\{{field_name}}, \{{options_for_validator}})
              should_break = true
            end
          \{% end %}
        \{% end %}

        unless should_break
          field_errors = Array(String).new
          \{% for option_name, options_for_validator in validations %}
            \{% if nil != VALIDATORS[option_name.id] %}
              unless \{{VALIDATORS[option_name.id][:method]}}(\{{field_name}}, \{{options_for_validator}})
                field_errors << \{{VALIDATORS[option_name.id][:key]}}
              end
            \{% end %}
          \{% end %}
          @errors["\{{field_name.id}}"] = field_errors unless field_errors.empty?
        end
      end

      # pretty much the same like __validate_field macro, but for the array of basic types, so iterare over the array
      macro __validate_inner_of_field(field_name, inner_validations)
        \{{field_name.id}}.not_nil!.each.with_index do |value, index|
          should_break = false
          \{% for option_name, options_for_validator in inner_validations %}
            \{% if nil != BREAKER_VALIDATORS[option_name.id] %}
              if \{{BREAKER_VALIDATORS[option_name.id][:method]}}(value, \{{options_for_validator}})
                should_break = true
              end
            \{% end %}
          \{% end %}

          unless should_break
            inner_field_errors = Array(String).new
            \{% for option_name, options_for_validator in inner_validations %}
              \{% if nil != VALIDATORS[option_name.id] %}
                unless \{{VALIDATORS[option_name.id][:method]}}(value, \{{options_for_validator}})
                  inner_field_errors << \{{VALIDATORS[option_name.id][:key]}}
                end
              \{% end %}
            \{% end %}
            @errors["\{{field_name.id}}.#{index}"] = inner_field_errors unless inner_field_errors.empty?
          end
        end
      end

      # the heart of validation logic
      # 1. empty the @erros property
      # 2. iterate over all fields
      #   2.1 switch between the field types and call validations (everything but nested_contract), nested validations (arrays) 
      #       and inner validation (arrays of simple types)
      # 3. calls validate method (custom validations)
      # 4. returns bool if there are any errors
      def validate!
        @errors = {} of String => Array(String)
        {% for field_name, options in PROPERTIES %}
          # Nested Contracts may have validations, but carefull with type. They can validate themself, we just need to concat the errors.
          {% if [:nested, :nested_contract].includes? options[:type] %}
            {% if nil != options[:validates] %}
              __validate_field {{field_name.id}}, {{options[:validates].id}}
            {% end %}
            if {{field_name.id}} && !{{field_name.id}}.not_nil!.valid?
              {{field_name.id}}.not_nil!.errors.each do |key, errors|
                @errors["{{field_name.id}}.#{key}"] = errors 
              end
            end
          # Arrays of contract share the same validations with arrays, but need to run inner contract validations.  
          {% elsif :array_of_contracts == options[:type] %}
            {% if nil != options[:validates] %}
              __validate_field {{field_name.id}}, {{options[:validates].id}}
            {% end %}
            if !{{field_name.id}}.is_a?(Nil) && {{field_name.id}}.not_nil!.any?
              {{field_name.id}}.not_nil!.each.with_index do |nested_contract_field, index|
                unless nested_contract_field.valid?
                  nested_contract_field.errors.each do |key, errors|
                    @errors["{{field_name.id}}.#{index}.#{key}"] = errors 
                  end
                end
              end
            end
          # Arrays of basic types can be validated as arrays and the inner elements can also be validated  
          {% elsif :array == options[:type] %}
            {% if nil != options[:validates] %}
              __validate_field {{field_name.id}}, {{options[:validates].id}}
            {% end %}
            {% if nil != options[:validates_inner] %}
              if !{{field_name.id}}.is_a?(Nil) && {{field_name.id}}.not_nil!.any?
                __validate_inner_of_field {{field_name.id}}, {{options[:validates_inner].id}}
              end
            {% end %}
          # simple field validation  
          {% else %}
            {% if nil != options[:validates] %}
              __validate_field {{field_name.id}}, {{options[:validates].id}}
            {% end %}
          {% end %}
        {% end %}

        {% if nil != CUSTOM_VALIDATIONS[:validate] %}
          {{CUSTOM_VALIDATIONS[:validate]}}
        {% end %}
        @errors.empty?
      end

    end


  end
end