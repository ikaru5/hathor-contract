module Hathor
  module Validation
    module MaxValidator

      def validate_maximum(value : (String | Array), option, **options)
        value.size <= option
      end

      def validate_maximum(value : (Int | Float), option, **options)
        value <= option
      end
      
      def validate_maximum(value, option, **options)
        true # must return true if no fitting type
      end

    end
  end
end