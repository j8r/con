class Object
  def from_con(string : String)
    new CON::PullParser.new string
  end
end

{% for type in %w(String Bool Int64 Float64 Nil) %}
def {{type.id}}.from_con(pull : CON::PullParser) : {{type.id}}
  if !(value = pull.read_value).is_a? {{type.id}}
    raise CON::MappingError.new value, {{type.id}}, pull
  end
  value
end

# :nodoc:
def {{type.id}}.from_con(value : CON::Type | CON::Token, pull : CON::PullParser) : {{type.id}}
  raise CON::MappingError.new value, {{type.id}}, pull if !value.is_a? {{type.id}}
  value
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
  def self.from_con(pull : CON::PullParser)
    array = Array(T).new
    pull.read_array do |value|
      array << T.from_con value, pull
    end
    array
  end

  # :nodoc:
  def self.from_con(value, pull : CON::PullParser)
    array = Array(T).new
    pull.read_array_unchecked do |value|
      array << T.from_con value, pull
    end
    array
  end
end
