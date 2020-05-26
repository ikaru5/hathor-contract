module Hathor
  module Validation
    module EmailValidator

      def validate_email(value : String, option, **options)
        value =~ /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/
      end


      def validate_email(value, option, **options)
        true # must return true if no fitting type
      end

    end
  end
end