module Hathor
  module Validation
    module AllowBlankBreaker

      def break_on_absence(value : (String | Array), option, **options)
        if option
          value.empty?
        end
      end
      
      def break_on_absence(value : Nil, option, **options)
        option # this will cover the most data types
      end

      def break_on_absence(value, option, **options)
        false # must return false if no fitting type
      end

    end
  end
end