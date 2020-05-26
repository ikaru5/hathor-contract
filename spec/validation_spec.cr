require "./spec_helper"

# this spec should test the validation logic, not the specific validators
describe TestContract do

  class Address < Hathor::Contract
    field street : String, validates: { presence: true, min: 3, max: 10 }
    field street_number : Int32, validates: { min: 5 }
    field plz : Int32, validates: { max: 120 }
    field city : String, validates: { max: 3, allow_blank: true }
  end

  class AddressTwo < Hathor::Contract
    field street : String
    field street_number : Int32
    field plz : Int32
    field city : String

    validates street, presence: true, min: 3, max: 10
    validates street_number, min: min_for_street_number
    validates plz, max: 120
    validates city, max: 3, allow_blank: true

    def min_for_street_number
      5
    end

    validate do
      if nil != street && "foobar" != street
        @errors["street"] ||= Array(String).new
        @errors["street"] << "not_foobar"
      end
    end
  end

  test "basic field validations on empty contract" do
    contract = Address.new
    assert contract.errors.empty?
    assert !contract.valid?
    assert !contract.errors.empty?
    assert 1 == contract.errors.size
    assert 1 == contract.errors["street"].size
    assert "not_present" == contract.errors["street"].first

    contract = AddressTwo.new
    assert contract.errors.empty?
    assert !contract.valid?
    assert !contract.errors.empty?
    assert 1 == contract.errors.size
    assert 1 == contract.errors["street"].size
    assert "not_present" == contract.errors["street"].first
  end

  test "basic field validation on contract with invalida data" do
    contract = Address.new
    contract.street = "too long string here"
    contract.street_number = 4
    contract.plz = 130
    contract.city = "Berlin"
    assert !contract.valid?
    assert 4 == contract.errors.size

    assert 1 == contract.errors["street"].size
    assert "gt_max" == contract.errors["street"].first
    assert 1 == contract.errors["street_number"].size
    assert "lt_min" == contract.errors["street_number"].first
    assert 1 == contract.errors["plz"].size
    assert "gt_max" == contract.errors["plz"].first
    assert 1 == contract.errors["city"].size
    assert "gt_max" == contract.errors["city"].first

    contract.street = "foobar"
    contract.street_number = 5
    contract.plz = 120
    contract.city = "Zoo"
    assert !contract.errors.empty?
    assert contract.valid?
    assert contract.errors.empty?

    contract = AddressTwo.new
    contract.street = "too long string here"
    contract.street_number = 4
    contract.plz = 130
    contract.city = "Berlin"
    assert !contract.valid?
    assert 4 == contract.errors.size

    assert 2 == contract.errors["street"].size
    assert "gt_max" == contract.errors["street"].first
    assert "not_foobar" == contract.errors["street"].last
    assert 1 == contract.errors["street_number"].size
    assert "lt_min" == contract.errors["street_number"].first
    assert 1 == contract.errors["plz"].size
    assert "gt_max" == contract.errors["plz"].first
    assert 1 == contract.errors["city"].size
    assert "gt_max" == contract.errors["city"].first

    contract.street = "foobar"
    contract.street_number = 5
    contract.plz = 120
    contract.city = "Zoo"
    assert !contract.errors.empty?
    assert contract.valid?
    assert contract.errors.empty?
  end

  class TestContractWithNesting < Hathor::Contract
    field email : String, validates: { presence: true, email: true }
    collection ages, of: Int32, validates: { max: 3 }, validates_inner: { min: 18 }
    nested! foo, validates: { presence: true } do
      field bar : String, validates: { min: 5 }
      nested foo, validates: { presence: true }  do
        field bar : String, validates: { max: 3 }
      end
    end
    nested_collection structur, validates: { presence: true, min: 2 } do
      nested_collection addresses, validates: { presence: true }, of: AddressTwo
      field! foobar : String
    end
  end

  test "collection and nesting based validation" do
    contract = TestContractWithNesting.new
    assert contract.errors.empty?
    assert !contract.valid?
    assert !contract.errors.empty?
    assert 3 == contract.errors.size
    
    assert 1 == contract.errors["email"].size
    assert "not_present" == contract.errors["email"].first
    assert 1 == contract.errors["foo.foo"].size
    assert "not_present" == contract.errors["foo.foo"].first
    assert 1 == contract.errors["structur"].size
    assert "not_present" == contract.errors["structur"].first

    # now put some invalid data
    contract.email = "not an email"
    contract.ages = [3,4,20,2]
    contract.foo.bar = "shor"
    contract.foo.new_foo
    contract.foo.foo.not_nil!.bar = "long"
    contract.new_structur
    contract.populate_structur
    contract.structur.not_nil!.first.new_addresses
    contract.structur.not_nil!.first.populate_addresses
    contract.structur.not_nil!.first.foobar = "thats even valid"
    assert !contract.valid?
    assert !contract.errors.empty?
    assert 9 == contract.errors.size

    assert 1 == contract.errors["email"].size
    assert "invalid_email" == contract.errors["email"].first
    assert 1 == contract.errors["ages"].size
    assert "gt_max" == contract.errors["ages"].first
    assert 1 == contract.errors["foo.bar"].size
    assert 1 == contract.errors["ages.0"].size
    assert "lt_min" == contract.errors["ages.0"].first
    assert 1 == contract.errors["ages.1"].size
    assert "lt_min" == contract.errors["ages.1"].first
    assert 1 == contract.errors["ages.3"].size
    assert "lt_min" == contract.errors["ages.3"].first
    assert "lt_min" == contract.errors["foo.bar"].first
    assert 1 == contract.errors["foo.foo.bar"].size
    assert "gt_max" == contract.errors["foo.foo.bar"].first
    assert 1 == contract.errors["structur"].size
    assert "lt_min" == contract.errors["structur"].first
    assert 1 == contract.errors["structur.0.addresses.0.street"].size
    assert "not_present" == contract.errors["structur.0.addresses.0.street"].first

    # finally put valid data
    contract.email = "some@test.com"
    contract.ages = [23,24,20]
    contract.foo.bar = "good string"
    contract.foo.foo.not_nil!.bar = "123"
    contract.populate_structur
    contract.structur.not_nil!.first.addresses.not_nil!.first.street = "foobar"
    contract.structur.not_nil![1].new_addresses
    contract.structur.not_nil![1].populate_addresses
    contract.structur.not_nil![1].addresses.not_nil!.first.street = "foobar"
    assert contract.valid?
    assert contract.errors.empty?
  end

  class TestContractWithNestingOut < Hathor::Contract
    field email : String
    collection ages, of: Int32
    nested! foo do
      field bar : String
      nested foo  do
        field bar : String, validates: { max: 3 }
      end

      validates bar, min: 5
      validates foo, presence: true 
    end
    nested_collection structur do
      nested_collection addresses, validates: { presence: true }, of: AddressTwo
      field! foobar : String
    end

    validates email, presence: true, email: true
    validates ages, max: 3
    validates_elements_of ages, min: 18
    validates foo, presence: true
    validates structur, presence: true, min: 2
  end

  test "collection and nesting based validation with validates" do
    contract = TestContractWithNestingOut.new
    assert contract.errors.empty?
    assert !contract.valid?
    assert !contract.errors.empty?
    assert 3 == contract.errors.size
    
    assert 1 == contract.errors["email"].size
    assert "not_present" == contract.errors["email"].first
    assert 1 == contract.errors["foo.foo"].size
    assert "not_present" == contract.errors["foo.foo"].first
    assert 1 == contract.errors["structur"].size
    assert "not_present" == contract.errors["structur"].first

    # now put some invalid data
    contract.email = "not an email"
    contract.ages = [3,4,20,2]
    contract.foo.bar = "shor"
    contract.foo.new_foo
    contract.foo.foo.not_nil!.bar = "long"
    contract.new_structur
    contract.populate_structur
    contract.structur.not_nil!.first.new_addresses
    contract.structur.not_nil!.first.populate_addresses
    contract.structur.not_nil!.first.foobar = "thats even valid"
    assert !contract.valid?
    assert !contract.errors.empty?
    assert 9 == contract.errors.size

    assert 1 == contract.errors["email"].size
    assert "invalid_email" == contract.errors["email"].first
    assert 1 == contract.errors["ages"].size
    assert "gt_max" == contract.errors["ages"].first
    assert 1 == contract.errors["ages.0"].size
    assert "lt_min" == contract.errors["ages.0"].first
    assert 1 == contract.errors["ages.1"].size
    assert "lt_min" == contract.errors["ages.1"].first
    assert 1 == contract.errors["ages.3"].size
    assert "lt_min" == contract.errors["ages.3"].first
    assert 1 == contract.errors["foo.bar"].size
    assert "lt_min" == contract.errors["foo.bar"].first
    assert 1 == contract.errors["foo.foo.bar"].size
    assert "gt_max" == contract.errors["foo.foo.bar"].first
    assert 1 == contract.errors["structur"].size
    assert "lt_min" == contract.errors["structur"].first
    assert 1 == contract.errors["structur.0.addresses.0.street"].size
    assert "not_present" == contract.errors["structur.0.addresses.0.street"].first

    # finally put valid data
    contract.email = "some@test.com"
    contract.ages = [23,24,20]
    contract.foo.bar = "good string"
    contract.foo.foo.not_nil!.bar = "123"
    contract.populate_structur
    contract.structur.not_nil!.first.addresses.not_nil!.first.street = "foobar"
    contract.structur.not_nil![1].new_addresses
    contract.structur.not_nil![1].populate_addresses
    contract.structur.not_nil![1].addresses.not_nil!.first.street = "foobar"
    assert contract.valid?
    assert contract.errors.empty?
  end

end
