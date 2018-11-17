require "big"

def BigInt.new(pull : CON::PullParser)
  BigInt.new pull.read_value
end

def BigFloat.new(pull : CON::PullParser)
  BigFloat.new pull.read_value
end

def BigDecimal.new(pull : CON::PullParser)
  BigDecimal.new pull.read_value
end
