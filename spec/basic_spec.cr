require "./spec_helper"

describe TestContractBasics do

  class TestContract < Hathor::Contract
    field text : String
    field number : Int32
  end

  test "it must be initialized without arguments and keep data" do
    contract = TestContract.new
    assert nil == contract.number
    assert nil == contract.text
    contract.number = 10
    contract.text = "some string"
    assert 10 == contract.number
    assert "some string" == contract.text
  end

  test "it should build from named tuple" do
    tuple = {number: 11, text: "test string"}
    contract = TestContract.from_hash(tuple)
    assert 11 == contract.number
    assert "test string" == contract.text

    tuple = {number: nil, text: "test string"}
    contract = TestContract.from_hash(tuple)
    assert nil == contract.number
    assert "test string" == contract.text

    tuple = {number: nil, text: nil}
    contract = TestContract.from_hash(tuple)
    assert nil == contract.number
    assert nil == contract.text

    tuple = {number: 11}
    contract = TestContract.from_hash(tuple)
    assert 11 == contract.number
    assert nil == contract.text
  end

  test "it should build from named hash" do
    hash = { :number => 11, :text => "test string" }
    contract = TestContract.from_hash(hash)
    assert 11 == contract.number
    assert "test string" == contract.text

    hash = { :number => nil, :text => "test string" }
    contract = TestContract.from_hash(hash)
    assert nil == contract.number
    assert "test string" == contract.text

    hash = { :number => nil, :text => nil }
    contract = TestContract.from_hash(hash)
    assert nil == contract.number
    assert nil == contract.text

    hash = { :number => 11 }
    contract = TestContract.from_hash(hash)
    assert 11 == contract.number
    assert nil == contract.text
  end

  class TestContractThree < Hathor::Contract
    field text : String
    field number : Int32
    field another_text : String
  end

  test "rendering to hash" do
    hash = { :text => "some text", :number => 13, :another_text => "some other text" }
    contract = TestContractThree.from_hash(hash)
    assert hash == contract.to_hash
  end

  test "parsing json" do
    json_string = "{\"text\":\"some text\",\"number\":13,\"anotherText\":\"some other text\"}"
    contract = TestContractThree.from_json(json_string)
    assert "some text" == contract.text
    assert "some other text" == contract.another_text
    assert 13 == contract.number

    json_string = "{\"number\":13,\"anotherText\":\"some other text\"}"
    contract = TestContractThree.from_json(json_string)
    assert nil == contract.text
    assert "some other text" == contract.another_text
    assert 13 == contract.number
  end

  class TestContractNested < Hathor::Contract
    field text : String
    field number : Int32
    nested address do
      field street : String
      field street_number : Int32
    end

    field another_text : String
  end

  test "it must be initialized without arguments and keep data also for nested" do
    contract = TestContractNested.new
    contract.new_address
    assert nil == contract.number
    assert nil == contract.text
    assert nil == contract.another_text
    assert nil == contract.address.not_nil!.street
    assert nil == contract.address.not_nil!.street_number
    contract.number = 10
    contract.text = "some string"
    contract.address.not_nil!.street = "teststreet"
    contract.address.not_nil!.street_number = 12
    contract.another_text = "some other string"
    assert 10 == contract.number
    assert "some string" == contract.text
    assert "some other string" == contract.another_text
    assert "teststreet" == contract.address.not_nil!.street
    assert 12 == contract.address.not_nil!.street_number
  end

  class TestContractNestedRequired < Hathor::Contract
    field text : String
    field required_text : String
    field number : Int32
    nested address do
      field street : String
      field street_number : Int32
    end

    nested second_address, nilable: false do
      field street : String
      field street_number : Int32
    end

    nested! third_address do
      field street : String
      field street_number : Int32
    end

    field another_text : String
  end

  test "nilable option and required flag" do
    contract = TestContractNestedRequired.new
    contract.new_address

    assert nil == contract.number
    assert nil == contract.text
    assert nil == contract.another_text
    assert nil == contract.address.not_nil!.street
    assert nil == contract.address.not_nil!.street_number
    assert nil == contract.second_address.street
    assert nil == contract.second_address.street_number
    assert nil == contract.third_address.street
    assert nil == contract.third_address.street_number

    contract.number = 10
    contract.text = "some string"
    contract.another_text = "some other string"
    contract.address.not_nil!.street = "teststreet"
    contract.address.not_nil!.street_number = 12
    contract.second_address.street = "other teststreet"
    contract.second_address.street_number = 14
    contract.third_address.street = "third teststreet"
    contract.third_address.street_number = 17

    assert 10 == contract.number
    assert "some string" == contract.text
    assert "some other string" == contract.another_text
    assert "teststreet" == contract.address.not_nil!.street
    assert 12 == contract.address.not_nil!.street_number
    assert "other teststreet" == contract.second_address.street
    assert 14 == contract.second_address.street_number
    assert "third teststreet" == contract.third_address.street
    assert 17 == contract.third_address.street_number
  end

  class TestContractDeepNested < Hathor::Contract
    field text : String
    field number : Int32
    nested! first_level do
      field street : String
      field street_number : Int32
      nested! second_level do
        field street : String
        field street_number : Int32
        nested! third_level do
          field street : String
        end
      end
    end
  end

  test "nilable option and required flag" do
    contract = TestContractDeepNested.new
    assert nil == contract.number
    assert nil == contract.text
    assert nil == contract.first_level.street
    assert nil == contract.first_level.street_number
    assert nil == contract.first_level.second_level.street
    assert nil == contract.first_level.second_level.street_number
    assert nil == contract.first_level.second_level.third_level.street

    contract.number = 12
    contract.text = "test 1"
    contract.first_level.street = "test 2"
    contract.first_level.street_number = 22
    contract.first_level.second_level.street = "test 3"
    contract.first_level.second_level.street_number = 33
    contract.first_level.second_level.third_level.street = "test 4"

    assert 12 == contract.number
    assert "test 1" == contract.text
    assert "test 2" == contract.first_level.street
    assert 22 == contract.first_level.street_number
    assert "test 3" == contract.first_level.second_level.street
    assert 33 == contract.first_level.second_level.street_number
    assert "test 4" == contract.first_level.second_level.third_level.street
  end

  class TestContractNotNilable < Hathor::Contract
    field! text : String
    field! text_default : String, default: "Test TEST"
    field! number : Int32
    field! number_big : Int64, default: 1213
    field! number_float : Float32
    field! number_float_default : Float32, default: 123.123
    field! number_float_big : Float64
    field! is : Bool
    field! is_default : Bool, default: true
  end

  test "impicit nilable option for field" do
    contract = TestContractNotNilable.new
    assert -1 == contract.number
    assert 1213 == contract.number_big
    assert -1 == contract.number_float
    assert 123.123.to_f32 == contract.number_float_default
    assert -1 == contract.number_float_big
    assert "" == contract.text
    assert "Test TEST" == contract.text_default
    assert false == contract.is
    assert true == contract.is_default
  end

  class TestContractWithArray < Hathor::Contract
    field text : String
    collection numbers, of: Int32
    field number : Int32
    collection names, of: String
    collection! safe_names, of: String
  end

  test "contract and basic array functionality" do
    # create contract
    contract = TestContractWithArray.new
    assert nil == contract.number
    assert nil == contract.text
    assert nil == contract.names
    assert nil != contract.safe_names
    assert nil == contract.numbers

    # set some values
    contract.number = 12
    contract.text = "test 1"
    contract.names = ["Kristin", "Tom", "Paul"]
    contract.safe_names = ["Hans", "Thorsten", "Frank"]
    contract.numbers = [2, 45, 111]

    # check the values
    assert 12 == contract.number
    assert "test 1" == contract.text
    assert contract.names.is_a?(Array(String))
    names = contract.names.not_nil!
    assert names.includes? "Tom"
    assert names.includes? "Paul"
    assert names.includes? "Kristin"
    assert !names.includes? "Kirill"

    assert contract.safe_names.is_a?(Array(String))
    assert contract.safe_names.includes? "Hans"
    assert contract.safe_names.includes? "Thorsten"
    assert contract.safe_names.includes? "Frank"
    assert !contract.safe_names.includes? "Paul"

    assert contract.numbers.is_a?(Array(Int32))
    numbers = contract.numbers.not_nil!
    assert numbers.includes? 2
    assert numbers.includes? 45
    assert numbers.includes? 111
    assert !numbers.includes? 123
  end
end
