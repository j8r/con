require "big"

struct BigInt
  def self.from_con(pull : CON::PullParser) : BigInt
    BigInt.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser) : BigInt
    pull.type_error value, Int64 | String if !value.is_a? Int64 | String
    BigInt.new value
  end
end

{% for big in %w(BigDecimal BigFloat) %}
struct {{big.id}}
  def self.from_con(pull : CON::PullParser) : {{big.id}}
    {{big.id}}.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser) : {{big.id}}
    pull.type_error value, String | Int64 | Float64 if !value.is_a? String | Int64 | Float64
    {{big.id}}.new value
  end
end
{% end %}
