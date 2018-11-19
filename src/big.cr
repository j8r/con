require "big"

struct BigInt
  def self.from_con(pull : CON::PullParser) : BigInt
    BigInt.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser) : BigInt
    BigInt.new(pull.expect value, Int64 | String)
  end
end

{% for big in %w(BigDecimal BigFloat) %}
struct {{big.id}}
  def self.from_con(pull : CON::PullParser) : {{big.id}}
    {{big.id}}.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser) : {{big.id}}
    {{big.id}}.new pull.expect(value, String | Int64 | Float64)
  end
end
{% end %}
