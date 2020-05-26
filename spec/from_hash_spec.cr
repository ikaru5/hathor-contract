require "./spec_helper"

describe TestContractFromHash do

  class Address < Hathor::Contract
    field street : String
    field street_number : Int32
    field plz : Int32
    field city : String
  end

  class TestContract < Hathor::Contract
    field email : String
    field username : String
    field password : String
    field password_repeat : String
    field agb : Bool
    nested address_one do
      field street : String
      field street_number : Int32
      field plz : Int32
      field city : String
    end
    nested_contract! address_two : Address
  end

  def basic_test_hash
    {
      :email => "k.kulikov94@gmail.com",
      :username => "Ikarus",
      :password => "#pass",
      :password_repeat => "#pass",
      :agb => true,
      :address_one => {
        :street => "somestreet",
        :street_number => 123,
        :plz => 1123,
        :city => "Dresden"
      },
      :address_two => {
        :street => "foostreet",
        :street_number => 123,
        :plz => 1234,
        :city => "Chemnitz"
      }
    }
  end

  test "it must parse hash and assign values accordingly" do
    contract = TestContract.from_hash basic_test_hash
    # now check the values
    assert "k.kulikov94@gmail.com" == contract.email
    assert "Ikarus" == contract.username
    assert "#pass" == contract.password
    assert "#pass" == contract.password_repeat
    assert contract.agb.is_a?(Bool) && contract.agb
    assert "somestreet" == contract.address_one.not_nil!.street
    assert 123 == contract.address_one.not_nil!.street_number
    assert 1123 == contract.address_one.not_nil!.plz
    assert "Dresden" == contract.address_one.not_nil!.city
    assert "foostreet" == contract.address_two.street
    assert 123 == contract.address_two.street_number
    assert 1234 == contract.address_two.plz
    assert "Chemnitz" == contract.address_two.city
  end

  test "it must parse hash and fail assign values accordingly with decorate_json_style" do
    contract = TestContract.from_hash basic_test_hash, decorate_json_style: true
    # now check the values
    assert "k.kulikov94@gmail.com" == contract.email
    assert "Ikarus" == contract.username
    assert "#pass" == contract.password
    assert nil == contract.password_repeat
    assert contract.agb.is_a?(Bool) && contract.agb
    assert nil == contract.address_one
    assert nil != contract.address_two
    assert contract.address_two.is_a? Address
    assert nil == contract.address_two.street
    assert nil == contract.address_two.street_number
    assert nil == contract.address_two.plz
    assert nil == contract.address_two.city
  end

  test "it should produce a similiar hash on to_hash call" do
    contract = TestContract.from_hash basic_test_hash
    new_hash = contract.to_hash
    assert new_hash == basic_test_hash
  end

  class TestContractWithArrays < Hathor::Contract
    field email : String
    field username : String
    field password : String
    field password_repeat : String
    field agb : Bool
    nested address_one do
      field street : String
      field street_number : Int32
      field plz : Int32
      field city : String
    end
    nested_contract! address_two : Address
    collection names, of: String
    nested_collection addresses, of: Address
  end

  def advanced_test_hash
    {
      :email => "k.kulikov94@gmail.com",
      :username => "Ikarus",
      :password => "#pass",
      :password_repeat => "#pass",
      :agb => true,
      :address_one => {
        :street => "somestreet",
        :street_number => 123,
        :plz => 1123,
        :city => "Dresden"
      },
      :address_two => {
        :street => "foostreet",
        :street_number => 123,
        :plz => 1234,
        :city => "Chemnitz"
      },
      :names => ["Lisa", "Susan", "Peter"],
      :addresses => [
        {
          :street => "barstreet",
          :street_number => 321,
          :plz => 123456,
          :city => "Leipzig"
        },
        {
          :street => "foobarstreet",
          :street_number => 222,
          :plz => 1407,
          :city => "Berlin"
        }
      ]
    }
  end

  test "parse hash with arrays and exporting it to this hash again" do
    contract = TestContractWithArrays.from_hash advanced_test_hash
    new_hash = contract.to_hash
    assert new_hash == advanced_test_hash

    # now check the values
    assert "k.kulikov94@gmail.com" == contract.email
    assert "Ikarus" == contract.username
    assert "#pass" == contract.password
    assert "#pass" == contract.password_repeat
    assert contract.agb.is_a?(Bool) && contract.agb
    assert "somestreet" == contract.address_one.not_nil!.street
    assert 123 == contract.address_one.not_nil!.street_number
    assert 1123 == contract.address_one.not_nil!.plz
    assert "Dresden" == contract.address_one.not_nil!.city
    assert "foostreet" == contract.address_two.street
    assert 123 == contract.address_two.street_number
    assert 1234 == contract.address_two.plz
    assert "Chemnitz" == contract.address_two.city
    assert 2 == contract.addresses.not_nil!.size
    first_address = contract.addresses.not_nil!.first.not_nil!
    assert "barstreet" == first_address.street
    assert 321 == first_address.street_number
    assert 123456 == first_address.plz
    assert "Leipzig" == first_address.city
    second_address = contract.addresses.not_nil!.last.not_nil!
    assert "foobarstreet" == second_address.street
    assert 222 == second_address.street_number
    assert 1407 == second_address.plz
    assert "Berlin" == second_address.city
  end
end
