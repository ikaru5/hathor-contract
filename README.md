# Hathor Contracts

Class based data storage with validations and parsing/rendering from and to JSON or Hashes in Crystal.

Inspired by Ruby [Trailblazer](http://trailblazer.to) Reform.

- [About](#about)
- [Hathor Operations](#hathor-operations)
- [Installation](#installation)
- [Usage](#usage)
- [Class API](#class-api)
- [Instance API](#instance-api)
- [Macros](#macros)
    - [field](#field)
        - [field!](#field-1)
    - [collection](#collection)
        - [collection!](#collection-1)
    - [nested](#nested)
        - [nested!](#nested-1)
    - [nested_contract](#nested_contract)
        - [nested_contract!](#nested_contract-1)
    - [nested_collection](#nested_collection)
        - [nested_collection!](#nested_collection-1)
    - [validates](#validates)
    - [validate](#validate)
    - [register_validation](#register_validation)
    - [register_validation_breaker](#register_validation_breaker)
- [Validation](#validation)
    - [Validators](#validators)
    - [custom validations](#custom-validations)
- [Development](#development)
- [Contributing](#contributing)
- [Contributors and Contact](#contributors-and-contact)
- [Copyright](#copyright)
        
## About

If you are coming from from the Ruby and Rails world, you probably heard or used Trailblazer. 
It adds an additional abstraction level to encapsulate your business code from the framework and adds a nice 
syntactic sugar. 

Especially on Crystal we have a wider range of ongoing ORMs, so taking your validation dependancies out makes sense.

Hathor Contracts are a tiny hybrid between Contracts and Representer. 
They aim to parse incoming JSON or Hashes/NamedTuples to Instances, 
validate the data and also render the assigned data again.

## Hathor Operations

If you are looking for Trailblazer-like Operations, you may also have a look at [Hathor Operations](https://github.com/ikaru5/hathor-operation).
The shards are decoupled and have no dependencies to each other.

## Installation

Add this to your application's `shard.yml`:

```yaml
  hathor-contract:
    github: ikaru5/hathor-contract
    version: ~> 0.1.0
```

## Usage

```crystal
require "hathor-contract" # to avoid this every time, create a base class and inherit from it

class Address < Hathor::Contract
  field street : String
  field street_number : Int32

  validates street, presence: true
  validates street_number, presence: true, min: 0
end

class DemoContract < Hathor::Contract
  field! email : String # "!" indicates that is may not be Nil -> no not_nil! needed
  field agb : Bool
  nested address_one do # inline nested data
    field street : String, validates: { presence: true }
    field street_number : Int32, validates: { presence: true, min: 0 }
  end
  nested_contract! address_two : Address # nested data by another contract
  collection names, of: String # Array of basic data types
  nested_collection addresses, of: Address # Array of contracts
end

# ...
contract = DemoContract.from_json json_string
# or
contract = DemoContract.from_hash { email: "test@email.com", ...}
# or 
contract = DemoContract.new # not nilabale fields will be set to defaults

# setter and getter
contract.addresses[0].street = "some street"
puts contract.addresses[0].street

# render a contract to something
puts contract.to_hash
puts contract.to_json
```

## Goals

- **Performance**: Since you are using Crystal you are probably looking for something faster than Ruby. 
So the main goal is not compromising performance in favor of syntactic sugar.
- **Maintainability**: Crystal is changing pretty fast, so a lot of things may seem redundant and 
the code may take a few more lines than needed.
- **Clarity and Comprehensibility**: Hathor does **not** aim to be the Crystals *high-level architecture*. 
Its a tiny lib for syntactic sugar in big and small projects. 

 
## Class API

```crystal
# from_json
# uses JSON.parse(json_string); decorate option will translate camelcase to crystals underscore syntax
Hathor::Contract.from_json(json_string : String, decorate : Bool = true) 

# from_hash
# used also for from_json; decorate option will translate camelcase to crystals underscore syntax
Hathor::Contract.from_hash(hash, decorate_json_style : Bool = false) 

# new
# simply create a new empty contract
Hathor::Contract.new
```

## Instance API

```crystal
# to_json
# returns JSON string; decorate option to get camelcase, instead of underscore
contract.to_json(decorate : Bool = true) 

# to_hash
# returns NamedTuple, decorate_json_style options used by to json
contract.to_hash(decorate_json_style : Bool = false) 

# valid? and validate!
# run validations and return boolean 
contract.valid? # recommended if you want the boolean
# or 
contract.validate! # returns boolean now, but may change in future

# errors
# get the errors
contract.errors
contract.errors["street"] # => ["not_present"]
contract.errors["addresses.0.street"] # => ["not_present"]
```

## Macros

The macros are written to be straight forward and most importantly *fast* during resulting execution.
An example of what it means: It is possible to reduce everything to one macro -
`field`. But there would be much more `if ... else` in resulting code and the speed and maintainability would suffer.

The current macros do things like decorating the attributes during compilation, not execution! Thats great for performance.  

All macros expands to a simple [property](https://crystal-lang.org/api/0.20.1/Class.html#property%28%2Anames%29-macro) macro. 

### field

This is straight forward. A simple property of defined type and Nil.

```crystal
# macro field(type_declaration, **options)
field field_name : Int32
```
#### field!

Shortcut to *nilable: **false***: `field something : Int32, nilable: false`

### collection

This is an array of simple data types and Nil.

```crystal
# macro collection(name, **options)
collection collection_name, of: String
```
#### collection!

Shortcut to *nilable: **false***: `collection something, of: Int32, nilable: false`

### nested

Will create an inline contract and a field with its class as data type.

```crystal
# macro nested(name, **options)
nested nested_name do
  # in fact this creates an inline Contract and a field with the type of this contract 
  # so use everthing from macros
end
```

**NOTE** If nilable, it will define a method `new_nested_name` to create an empty field with correct data type.

#### nested!

Shortcut to *nilable: **false***: `nested something, nilable: false do ...`

### nested_contract

Pretty much the same as nested, but you have to provide a contract class.

```crystal
# macro nested_contract(name, **options)
nested_contract nested_contract_name : AnotherContract
```
#### nested_contract!

Shortcut to *nilable: **false***: `nested_contract something : AnotherContract, nilable: false`

### nested_collection

This will create a property of an array of contracts.
You may define a block for an inline contract or use the `of:`-option to define a contract type.

```crystal
# macro nested_collection(name, **options, &block)
nested nested_collection_name do
  # in fact this creates an inline Contract and a field with an Array of the type of this contract 
  # so use everthing from macros
end

# or 
nested nested_collection_name of: AnotherContract
```

**NOTE** If nilable, it will define a method `new_nested_collection_name` to create an empty array with correct data type.
**NOTE** It will also define a method `populate_nested_collection_name` populate the array with new data if array is present.

#### nested_collection!

Shortcut to *nilable: **false***: `nested_collection something, nilable: false do ...`

#### validates

A macro to define validations for any field. Learn more: [Validation](#validation).

#### validate

A macro to define custom validations by passing a block of code to run at the end of validations. 
Learn more: [Validation](#validation).

#### register_validation

Learn more [Validation](#Validators)

``` crystal
# register a validator module
# option - name of option used in validates
# method - method defined in validator
# key - error string to add if validation fails
macro register_validation(option, method, key)
```

#### register_validation_breaker
Learn more [Validation](#Validators)

``` crystal
# register a validator module as breaker
# option - name of option used in validates
# method - method defined in validator
macro register_validation_breaker(option, method)
```

## Validation

Hathor Contracts offers two types of validations: 
 - simple validators (min, max, presence)
 - validation breakers (allow_blank)
 
If a validation breaker passes, it will prevent other validations from running and the field will be valid. 
Just think about allow_blank. **Breakers do not add any errors.**

The contract has an `@errors = {} of String => Array(String)` property, which will be filled with the error keys/codes 
to corresponding fields.
A contract is invalid if @errors has any keys in it. 

You can define validations, by passing them in `validates` or `validates_inner` options.
Or you can use `validates` or `validates_elements_of` macros if you want to write them decoupeled.
You can use both styles in the same contract, but dont mix it for one field.

#### Example: 

```crystal
  class TestContract < Hathor::Contract
    field email : String, validates: { presence: true, email: true }
    collection ages, of: Int32, validates: { max: 3 }, validates_inner: { min: 18 }
    nested! foo, validates: { presence: true } do
      field bar : String, validates: { min: 5 }
      nested foo, validates: { presence: true }  do
        field bar : String, validates: { max: 3 }
      end
    end
    nested_collection structur, validates: { presence: true } do
      nested_collection addresses, validates: { presence: true }, of: AddressTwo
      field! foobar : String
    end
  end

  # this contract is written decoupeled
  class AddressTwo < Hathor::Contract
    field street : String
    field street_number : Int32
    field plz : Int32
    field city : String

    validates street, presence: true, min: 3, max: 10
    validates street_number, min: min_for_street_number # function call example
    validates plz, max: 120
    validates city, max: 3, allow_blank: true
  
    # access functions for validations
    def min_for_street_number
      5
    end
  
    # custom validations, do what ever you need
    validate do
      if nil != street && "foobar" != street
        @errors["street"] ||= Array(String).new
        @errors["street"] << "not_foobar"
      end
    end

  end

```

#### Validators

**Note:** There are just a few valiators right now. This will change in future releases. 
If you have any wishes or want to contribute new validators, than please look at [Contributors and Contact](#contributors-and-contact). 

The available validations are based on Validator Modules. A Validator module defines validation methods for the specific 
data type. The correct method will be selected by crystal through simple overloading. 
If there is no fitting type, the validation will silently succeed. Also if the passed option *disables* the validator, 
it will also pass. So `presence: false` will always pass. For absence there is the Absence validator: `absence: true`.

#### Example of a validator module:
``` crystal
module Hathor
  module Validation
    # thanks to overloading we can cleanly apply it to Strings, Arrays and Numbers.
    module MaxValidator
      
      def validate_maximum(value : (String | Array), option, **options)
        value.size <= option
      end

      def validate_maximum(value : (Int | Float), option, **options)
        value <= option
      end
      
      def validate_maximum(value : Nil, option, **options)
        true # we can also define specific behaviour for Nil
      end

      def validate_maximum(value, option, **options)
        true # must return true if no fitting type
      end

    end
  end
end    
```

To register the Validator we use following macros in the contract:

```crystal
include MaxValidator # dont forget to include the module

register_validation max, validate_maximum, "gt_max"
# or for breakers
register_validation_breaker allow_blank, break_on_absence

```

If you want to add a lot of own validators, you can create your own base contract class. 
Include and register your validators and let all other contracts inherit from it.
In the upcoming release this will be documented and more customizitaion options will be added.

#### Custom validations

You can use the `validate` macro to add custom code at the end of validations.
Just add an error to the @errors property

```crystal
class Address < Hathor::Contract
    field street : String
    # ...

    validate do
      if nil != street && "foobar" != street
        @errors["street"] ||= Array(String).new
        @errors["street"] << "not_foobar"
      end
    end
  end
```

## Development

- [ ] custimizable contract base class
- [ ] customizable json parsing/rendering
- [ ] more validations (skip, between, ... and more)
- [ ] Logging - its ugly right now and doesnt work bcs of crystal 0.34 Log changes. will be fixed with release of crystal 0.35 
- [ ] parse params: as, parse_name, render_rame, render: Bool, parse: Bool - options
- [ ] inheritance support - should work out of the box, but a `remove` - macro would be nice
- [ ] error and exception handling
- [ ] ... even more possibilities

## Contributing

1. Fork it (<https://github.com/your-github-user/schemas/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors and Contact

If you have ideas on how to develop hathor more or what features it is missing, I would love to hear about it.
You can always contact me on [gitter](https://gitter.im/amberframework/amber) @ikaru5 or E-Mail.

- [@ikaru5](https://github.com/ikaru5) Kirill Kulikov - creator, maintainer

## Copyright

Copyright (c) 2020 Kirill Kulikov <k.kulikov94@gmail.com>

`hathor-constracts` is released under the [MIT License](http://www.opensource.org/licenses/MIT).