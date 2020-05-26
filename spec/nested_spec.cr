require "./spec_helper"

describe TestContractNested do

  class InnerContract < Hathor::Contract
    field text : String
    field other_text : String
    field number : Int32
  end

  class TestContractNested < Hathor::Contract
    field text : String
    field number : Int32
    nested! address do
      field street : String
      field street_number : Int32
    end
    nested_contract some : InnerContract # thats the important thing here
    nested_contract! other : InnerContract # thats the important thing here
    field another_text : String
  end

  test "it must be initialized without arguments and keep data also for nested" do
    contract = TestContractNested.new
    contract.some = InnerContract.new
    assert nil == contract.number
    assert nil == contract.text
    assert nil == contract.another_text
    assert nil == contract.address.street
    assert nil == contract.address.street_number
    assert nil == contract.some.not_nil!.text
    assert nil == contract.some.not_nil!.other_text
    assert nil == contract.some.not_nil!.number
    assert nil == contract.other.text
    assert nil == contract.other.other_text
    assert nil == contract.other.number
    # now set some values
    contract.number = 10
    contract.text = "some string"
    contract.address.street = "teststreet"
    contract.address.street_number = 12
    contract.another_text = "some other string"
    contract.some.not_nil!.text = "foobar 1"
    contract.some.not_nil!.other_text = "foobar 2"
    contract.some.not_nil!.number = 13
    contract.other.text = "foobar 12"
    contract.other.other_text = "foobar 22"
    contract.other.number = 15
    # now check the values
    assert 10 == contract.number
    assert "some string" == contract.text
    assert "some other string" == contract.another_text
    assert "teststreet" == contract.address.not_nil!.street
    assert 12 == contract.address.not_nil!.street_number
    assert "foobar 1" == contract.some.not_nil!.text
    assert "foobar 2" == contract.some.not_nil!.other_text
    assert 13 == contract.some.not_nil!.number
    assert "foobar 12" == contract.other.text
    assert "foobar 22" == contract.other.other_text
    assert 15 == contract.other.number
  end

end
