module Hathor
  module Validation
    module AbsenceValidator
      # NOTE: absence validator, is not presence validator, if defined abssence: false, it simply has no effect
      # this is only my opinion... if you dissagree, write me on gitter or simply redefine it 

      def validate_absence(value : (String | Array), option, **options)
        if option
          value.empty?
        end
      end
      
      def validate_absence(value : Nil, option, **options)
        true # this will cover the most data types
      end

      def validate_absence(value, option, **options)
        false # must return false if no fitting type
      end

    end
  end
end