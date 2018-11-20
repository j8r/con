require "./pull_parser"

class Object
  def from_con(con : String | IO)
    from_con CON::PullParser.new(con)
  end
end

{% begin %}
{% integers = %w(Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64) %}
{% for type in integers %}
def {{type.id}}.from_con(value : CON::Type | CON::Token, pull : CON::PullParser) : {{type.id}}
  {{type.id}}.new(pull.expect value, Int64)
end
{% end %}

{% con_types = %w(String Bool Int64 Nil) %}
{% for type in con_types %}
# :nodoc:
def {{type.id}}.from_con(value : CON::Type | CON::Token, pull : CON::PullParser) : {{type.id}}
  pull.expect value, {{type.id}}
end
{% end %}

{% for type in integers + con_types + %w(Float32 Float64) %}
def {{type.id}}.from_con(pull : CON::PullParser) : {{type.id}}
  {{type.id}}.from_con pull.read_value, pull
end
{% end %}
{% end %}

{% for float in %w(32 64) %}
def Float{{float.id}}.from_con(value : CON::Type | CON::Token, pull : CON::PullParser) : Float{{float.id}}
  pull.expect(value, Float64 | Int64).to_f{{float.id}}
end
{% end %}

class Hash
  def self.from_con(pull : CON::PullParser)
    hash = Hash(K, V).new
    pull.read_document do |key|
      hash[key] = V.from_con pull
    end
    hash
  end

  # :nodoc:
  def self.from_con(value, pull : CON::PullParser)
    hash = Hash(K, V).new
    pull.read_hash_unchecked do |key|
      hash[key] = V.from_con pull
    end
    hash
  end
end

class Array
  def self.from_con(pull : CON::PullParser) : Array(T)
    if !(value = pull.read_value_unchecked).is_a? CON::Token::BeginArray
      pull.type_error value, CON::Token::BeginArray
    end
    Array(T).from_con nil, pull
  end

  # :nodoc:
  def self.from_con(value, pull : CON::PullParser) : Array(T)
    array = Array(T).new
    pull.read_array_unchecked do |value|
      array << T.from_con value, pull
    end
    array
  end
end

struct Tuple
  def self.from_con(pull : CON::PullParser)
    if !(value = pull.read_value_unchecked).is_a? CON::Token::BeginArray
      pull.type_error value, CON::Token::BeginArray
    end
    T.from_con nil, pull
  end

  def self.from_con(value, pull : CON::PullParser)
    {% begin %}
    tuple = Tuple.new(
      {% for i in 0...T.size %}
        (self[{{i}}].from_con(pull.read_value_unchecked, pull)),
      {% end %}
    )
    if !(value = pull.read_value_unchecked).is_a? CON::Token::EndArray
      pull.type_error value, CON::Token::EndArray
    end
    tuple
    {% end %}
  end
end

struct NamedTuple
  def self.from_con(pull : CON::PullParser)
    {% begin %}
    {% for key in T.keys %}
      %var{key.id} = nil
    {% end %}

    pull.read_document do |key|
      case key
        {% for key, type in T %}
          when {{key.stringify}}
            %var{key.id} = {{type}}.from_con(pull)
        {% end %}
      else
        pull.skip_value
      end
    end

    {% for key in T.keys %}
      if %var{key.id}.nil?
        pull.type_error %var{key.id}, CON::Type
      end
    {% end %}

    {
      {% for key in T.keys %}
        {{key}}: %var{key.id},
      {% end %}
    }
    {% end %}
  end

  def self.from_con(value, pull : CON::PullParser)
    {% begin %}
    {% for key in T.keys %}
      %var{key.id} = nil
    {% end %}

    pull.read_hash_unchecked do |key|
      case key
        {% for key, type in T %}
          when {{key.stringify}}
            %var{key.id} = {{type}}.from_con(pull)
        {% end %}
      else
        pull.skip_value
      end
    end

    {% for key in T.keys %}
      if %var{key.id}.nil?
        pull.type_error %var{key.id}, CON::Type
      end
    {% end %}

    {
      {% for key in T.keys %}
        {{key}}: %var{key.id},
      {% end %}
    }
    {% end %}
  end
end

struct Union
  def self.from_con(pull : CON::PullParser)
    self.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser)
    {% begin %}
     case value
    {% for type in T %}
    {% if type.stringify.starts_with? "Array(" %}\
    when CON::Token::BeginArray then {{type.id}}.from_con value, pull
    {% elsif type.stringify.starts_with? "Hash(" %}\
    when CON::Token::BeginHash then {{type.id}}.from_con value, pull
    {% else %}\
    when {{type.id}} then  {{type.id}}.from_con value, pull
    {% end %}
    {% end %}
    else pull.expect value, {{T.join(" | ").id}}
    end
    {% end %}
  end
end

struct Enum
  def self.from_con(pull : CON::PullParser)
    self.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser)
    case value
    when String then parse value
    when Int64  then from_value value
    else             pull.expect value, String | Int64
    end
  end
end

struct Time
  def self.from_con(pull : CON::PullParser)
    Time.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser)
    Time::Format::ISO_8601_DATE_TIME.parse(pull.expect value, String)
  end

  struct Format
    def self.from_con(pull : CON::PullParser)
      Format.from_con pull.read_value, pull
    end

    def self.from_con(value, pull : CON::PullParser)
      parse pull.expect(value, String), Time::Location::UTC
    end
  end

  module EpochConverter
    def self.from_con(pull : CON::PullParser)
      EpochConverter.from_con pull.read_value, pull
    end

    def self.from_con(value, pull : CON::PullParser)
      Time.unix pull.type_error(value, Int64)
    end
  end

  module EpochMillisConverter
    def self.from_con(pull : CON::PullParser)
      EpochConverter.from_con pull.read_value, pull
    end

    def self.from_con(value, pull : CON::PullParser)
      Time.unix_ms pull.except(value, Int64)
    end
  end
end
