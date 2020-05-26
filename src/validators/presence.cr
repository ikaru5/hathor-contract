module Hathor
  module Validation
    module PresenceValidator
      # NOTE: presence validator, is not absence validator, if defined presence: false, it just has no effect
      # this is only my opinion... if you dissagree, write me on gitter or simply redefine it 

      def validate_presence(value : (String | Array), option, **options)
        if option
          !value.empty?
        end
      end
      
      def validate_presence(value : Nil, option, **options)
        !option # this will cover the most data types
      end

      def validate_presence(value, option, **options)
        true # must return true if no fitting type
      end

    end
  end
end