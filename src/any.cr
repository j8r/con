require "./pull_parser"

struct CON::Any
  alias Type = Nil | Bool | Int64 | Float64 | String | Array(Any) | Hash(String, Any)
  getter raw : Type

  # Initializing document
  def self.from_con(pull : CON::PullParser)
    case first_key = pull.read_key_unchecked
    when String
      hash = Hash(String, Any).new
      hash[first_key] = new pull.read_value, pull
      pull.read_document do |key|
        hash[key] = new pull.read_value, pull
      end
      new hash
    else
      new first_key, pull
    end
  end

  # :nodoc:
  def self.from_con(value : Token, pull : CON::PullParser)
    new value, pull
  end

  def self.new(token : Token, pull : CON::PullParser)
    case token
    when Token::BeginHash
      hash = Hash(String, Any).new
      pull.read_hash_unchecked do |key|
        hash[key] = new pull.read_value, pull
      end
      new hash
    when Token::BeginArray
      array = Array(Any).new
      pull.read_array_unchecked do |element|
        array << new element, pull
      end
      new array
    else
      raise "Unexpected token: #{token}"
    end
  end

  # Creates a `CON::Any` that wraps the given value.
  def initialize(@raw : Type, pull : CON::PullParser? = nil)
  end

  # Assumes the underlying value is an `Array` or `Hash` and returns its size.
  # Raises if the underlying value is not an `Array` or `Hash`.
  def size : Int
    case object = @raw
    when Array
      object.size
    when Hash
      object.size
    else
      raise "Expected Array or Hash for #size, not #{object.class}"
    end
  end

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index.
  # Raises if the underlying value is not an `Array`.
  def [](index : Int) : CON::Any
    case object = @raw
    when Array
      object[index]
    else
      raise "Expected Array for #[](index : Int), not #{object.class}"
    end
  end

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index, or `nil` if out of bounds.
  # Raises if the underlying value is not an `Array`.
  def []?(index : Int) : CON::Any?
    case object = @raw
    when Array
      object[index]?
    else
      raise "Expected Array for #[]?(index : Int), not #{object.class}"
    end
  end

  # Assumes the underlying value is a `Hash` and returns the element
  # with the given key.
  # Raises if the underlying value is not a `Hash`.
  def [](key : String) : CON::Any
    case object = @raw
    when Hash
      object[key]
    else
      raise "Expected Hash for #[](key : String), not #{object.class}"
    end
  end

  # Assumes the underlying value is a `Hash` and returns the element
  # with the given key, or `nil` if the key is not present.
  # Raises if the underlying value is not a `Hash`.
  def []?(key : String) : CON::Any?
    case object = @raw
    when Hash
      object[key]?
    else
      raise "Expected Hash for #[]?(key : String), not #{object.class}"
    end
  end

  # Traverses the depth of a structure and returns the value.
  # Returns `nil` if not found.
  def dig?(key : String | Int, *subkeys)
    if (value = self[key]?) && value.responds_to?(:dig?)
      value.dig?(*subkeys)
    end
  end

  # :nodoc:
  def dig?(key : String | Int)
    self[key]?
  end

  # Traverses the depth of a structure and returns the value, otherwise raises.
  def dig(key : String | Int, *subkeys)
    if (value = self[key]) && value.responds_to?(:dig)
      return value.dig(*subkeys)
    end
    raise "CON::Any value not diggable for key: #{key.inspect}"
  end

  # :nodoc:
  def dig(key : String | Int)
    self[key]
  end

  # Checks that the underlying value is `Nil`, and returns `nil`.
  # Raises otherwise.
  def as_nil : Nil
    @raw.as(Nil)
  end

  # Checks that the underlying value is `Bool`, and returns its value.
  # Raises otherwise.
  def as_bool : Bool
    @raw.as(Bool)
  end

  # Checks that the underlying value is `Bool`, and returns its value.
  # Returns `nil` otherwise.
  def as_bool? : Bool?
    as_bool if @raw.is_a?(Bool)
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
  # Raises otherwise.
  def as_i : Int32
    @raw.as(Int).to_i
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
  # Returns `nil` otherwise.
  def as_i? : Int32?
    as_i if @raw.is_a?(Int)
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
  # Raises otherwise.
  def as_i64 : Int64
    @raw.as(Int).to_i64
  end

  # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
  # Returns `nil` otherwise.
  def as_i64? : Int64?
    as_i64 if @raw.is_a?(Int64)
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float64`.
  # Raises otherwise.
  def as_f : Float64
    @raw.as(Float64)
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float64`.
  # Returns `nil` otherwise.
  def as_f? : Float64?
    @raw.as?(Float64)
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float32`.
  # Raises otherwise.
  def as_f32 : Float32
    @raw.as(Float).to_f32
  end

  # Checks that the underlying value is `Float`, and returns its value as an `Float32`.
  # Returns `nil` otherwise.
  def as_f32? : Float32?
    as_f32 if @raw.is_a?(Float)
  end

  # Checks that the underlying value is `String`, and returns its value.
  # Raises otherwise.
  def as_s : String
    @raw.as(String)
  end

  # Checks that the underlying value is `String`, and returns its value.
  # Returns `nil` otherwise.
  def as_s? : String?
    as_s if @raw.is_a?(String)
  end

  # Checks that the underlying value is `Array`, and returns its value.
  # Raises otherwise.
  def as_a : Array(Any)
    @raw.as(Array)
  end

  # Checks that the underlying value is `Array`, and returns its value.
  # Returns `nil` otherwise.
  def as_a? : Array(Any)?
    as_a if @raw.is_a?(Array)
  end

  # Checks that the underlying value is `Hash`, and returns its value.
  # Raises otherwise.
  def as_h : Hash(String, Any)
    @raw.as(Hash)
  end

  # Checks that the underlying value is `Hash`, and returns its value.
  # Returns `nil` otherwise.
  def as_h? : Hash(String, Any)?
    as_h if @raw.is_a?(Hash)
  end

  # :nodoc:
  def inspect(io)
    @raw.inspect(io)
  end

  # :nodoc:
  def to_s(io)
    @raw.to_s(io)
  end

  # :nodoc:
  def pretty_print(pp)
    @raw.pretty_print(pp)
  end

  # Returns `true` if both `self` and *other*'s raw object are equal.
  def ==(other : CON::Any)
    raw == other.raw
  end

  # Returns `true` if the raw object is equal to *other*.
  def ==(other)
    raw == other
  end

  # See `Object#hash(hasher)`
  def_hash raw

  # :nodoc:
  def to_json(json : CON::Builder)
    raw.to_json(json)
  end

  # Returns a new CON::Any instance with the `raw` value `dup`ed.
  def dup
    Any.new(raw.dup)
  end

  # Returns a new CON::Any instance with the `raw` value `clone`ed.
  def clone
    Any.new(raw.clone)
  end

  # :nodoc:
  def to_s(io)
    @raw.to_s(io)
  end

  # :nodoc:
  def pretty_print(pp)
    @raw.pretty_print(pp)
  end

  def to_con(con : CON::Builder)
    @raw.to_con con
  end

  def to_json(json : CON::Builder)
    @raw.to_json json
  end
end

class Object
  def ===(other : CON::Any)
    self === other.raw
  end
end

struct Value
  def ==(other : CON::Any)
    self == other.raw
  end
end

class Reference
  def ==(other : CON::Any)
    self == other.raw
  end
end

class Array
  def ==(other : CON::Any)
    self == other.raw
  end
end

class Hash
  def ==(other : CON::Any)
    self == other.raw
  end
end

class Regex
  def ===(other : CON::Any)
    value = self === other.raw
    $~ = $~
    value
  end
end
