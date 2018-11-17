require "./pull_parser"
require "./from_con"
require "./any"

module CON
  # The `CON.mapping` macro defines how an object is mapped to CON.
  #
  # ### Example
  #
  # ```
  # require "json"
  #
  # class Location
  #   CON.mapping(
  #     lat: Float64,
  #     lng: Float64,
  #   )
  # end
  #
  # class House
  #   getter address : String
  #   getter location : Location?
  #   JSON.mapping(
  #     address: "address",
  #     location: "location",
  #   )
  # end
  #
  # house = House.from_json(%({"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}))
  # house.address  # => "Crystal Road 1234"
  # house.location # => #<Location:0x10cd93d80 @lat=12.3, @lng=34.5>
  # house.to_json  # => %({"address":"Crystal Road 1234","location":{"lat":12.3,"lng":34.5}})
  #
  # houses = Array(House).from_json(%([{"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}]))
  # houses.size    # => 1
  # houses.to_json # => %([{"address":"Crystal Road 1234","location":{"lat":12.3,"lng":34.5}}])
  # ```
  #
  # ### Usage
  #
  # `CON.mapping` must receive a series of named arguments, or a named tuple literal, or a hash literal,
  # whose keys will associate a Crystal instance variable with a CON string key.

  # :nodoc:
  macro mapping_vars_declaration
  \{% for ivar in @type.instance_vars %}
    \{% if ivar.has_default_value? %}
       __\{{ivar}} : \{{ivar.type}} = \{{ivar.default_value}}
    \{% else %}\
       __\{{ivar}} : \{{ivar.type}} | Nil = nil
    \{% end %}
  \{% end %}
  end

  # Serializes the whole document as defined in the mapping, and put all unmapped data in the first defined argument variable, which must be a `Hash(String, CON::Any)`
  #
  # ```
  # struct Document
  #   getter others : Hash(String, CON::Any)
  #   property first_key : String
  #   CON.full_mapping(
  #     "others",
  #     first_key: "key"
  #   )
  # end
  # ```
  macro full_mapping(_all, **_properties)
  def initialize(_pull : CON::PullParser)
    CON.mapping_vars_declaration
    __{{_all.id}} = Hash(String, CON::Any).new
    _pull.read_document do |_key|
      case _key
      {% for key, value in _properties %}\
      when {{value}} then __{{key}} = {{key}}.class.from_con _pull
      {% end %}\
      else __{{_all.id}}[_key] = CON::Any.new _pull.read_value, _pull
      end
    end
    \{% for ivar in @type.instance_vars %}
      raise "'\{{ivar}}' must be \{{ivar.type}}, not Nil" if !__\{{ivar}}.is_a?(\{{ivar.type}})
      @\{{ivar}} =  __\{{ivar}}
    \{% end %}
  end
  def self.from_con(pull : CON::PullParser)
    new pull
  end
  end

  # The document to be serialized must match the defined mapping, else a `MappingError` will be raised
  macro strict_mapping(**_properties)
  def initialize(_pull : CON::PullParser)
    CON.mapping_vars_declaration
    _pull.read_document do |_key|
      case _key
      {% for key, value in _properties %}\
      when {{value}} then __{{key}} = {{key}}.class.from_con _pull
      {% end %}\
      end
    end
    \{% for ivar in @type.instance_vars %}
      raise "'\{{ivar}}' must be \{{ivar.type}}, not Nil" if !__\{{ivar}}.is_a?(\{{ivar.type}})
      @\{{ivar}} =  __\{{ivar}}
    \{% end %}
  end
  def self.from_con(pull : CON::PullParser)
    new pull
  end
  end

  # Serializes the keys defined in the mapping, and skip undefined ones
  macro lazy_mapping(**_properties)
  def initialize(_pull : CON::PullParser)
    CON.mapping_vars_declaration
    _pull.read_document do |_key|
      case _key
      {% for key, value in _properties %}\
      when {{value}} then __{{key}} = {{key}}.class.from_con _pull
      {% end %}\
      else _pull.skip
      end
    end
    \{% for ivar in @type.instance_vars %}
      raise "'\{{ivar}}' must be \{{ivar.type}}, not Nil" if !__\{{ivar}}.is_a?(\{{ivar.type}})
      @\{{ivar}} =  __\{{ivar}}
    \{% end %}
  end
  def self.from_con(pull : CON::PullParser)
    new pull
  end
  end

  class MappingError < ParseException
    def self.new(value, expected_type, pull : CON::PullParser, cause = nil)
      new "Expected #{expected_type}, got #{value.class} (#{value.inspect})", pull.line_number, pull.column_number, cause
    end
  end
end
