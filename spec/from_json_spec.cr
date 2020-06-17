require "./spec_helper"

# CAUTION! Json functionility makes usage of Hash functionality, so if something fails here its maybe related to hashes.
describe TestContractFromJson do

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

  test "it must parse json and assign values accordingly with decorate" do
    json = File.read "./spec/files/contract_json.json"
    contract = TestContract.from_json json, decorate: true
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
    # compare without whitespaces
    assert json.gsub(/[\s\n]*/, "") == contract.to_json.gsub(/[\s\n]*/, "")
    assert "{\"email\":\"k.kulikov94@gmail.com\",\"username\":\"Ikarus\",\"password\":\"#pass\",\"password_repeat\":\"#pass\",\"agb\":true,\"address_one\":{\"street\":\"somestreet\",\"street_number\":123,\"plz\":1123,\"city\":\"Dresden\"},\"address_two\":{\"street\":\"foostreet\",\"street_number\":123,\"plz\":1234,\"city\":\"Chemnitz\"}}" ==
        contract.to_json(decorate: false).gsub(/[\s\n]*/, "")
  end

  test "it must parse json and assign values accordingly without decorate" do
    json = File.read "./spec/files/contract_json.json"
    contract = TestContract.from_json json, decorate: false
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
    # compare without whitespaces
    assert "{\"email\":\"k.kulikov94@gmail.com\",\"username\":\"Ikarus\",\"password\":\"#pass\",\"passwordRepeat\":null,\"agb\":true,\"addressOne\":null,\"addressTwo\":{\"street\":null,\"streetNumber\":null,\"plz\":null,\"city\":null}}" ==
        contract.to_json(decorate: true).gsub(/[\s\n]*/, "")
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

  test "should parse json with arrays" do
    json = File.read "./spec/files/contract_json_complex.json"
    contract = TestContractWithArrays.from_json json
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
    assert ["Lisa", "Susan", "Peter"] == contract.names
    assert contract.addresses.is_a?(Array(TestContractFromJsonTest::Address))
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
    # compare without whitespaces
    assert "{\"email\":\"k.kulikov94@gmail.com\",\"username\":\"Ikarus\",\"password\":\"#pass\",\"passwordRepeat\":\"#pass\",\"agb\":true,\"addressOne\":{\"street\":\"somestreet\",\"streetNumber\":123,\"plz\":1123,\"city\":\"Dresden\"},\"addressTwo\":{\"street\":\"foostreet\",\"streetNumber\":123,\"plz\":1234,\"city\":\"Chemnitz\"},\"names\":[\"Lisa\",\"Susan\",\"Peter\"],\"addresses\":[{\"street\":\"barstreet\",\"streetNumber\":321,\"plz\":123456,\"city\":\"Leipzig\"},{\"street\":\"foobarstreet\",\"streetNumber\":222,\"plz\":1407,\"city\":\"Berlin\"}]}" ==
        contract.to_json(decorate: true).gsub(/[\s\n]*/, "")
  end

end
