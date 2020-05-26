module Hathor
  module Validation
    module MinValidator

      def validate_minimum(value : (String | Array), option, **options)
        value.size >= option
      end

      def validate_minimum(value : (Int | Float), option, **options)
        value >= option
      end
      
      def validate_minimum(value : Nil, option, **options)
        true
      end

      def validate_minimum(value, option, **options)
        true # must return true if no fitting type
      end

    end
  end
end