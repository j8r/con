require "spec"
require "../src/from_con"
require "../src/big"
require "../src/uuid"

describe "from_con" do
  describe "Array" do
  end
  it "does Array(Nil)#from_con" do
    Array(Nil).from_con("[nil nil]").should eq [nil, nil]
  end

  it "does Array(Bool)#from_con" do
    Array(Bool).from_con("[true false]").should eq [true, false]
  end

  it "does Array(Int32)#from_con" do
    Array(Int32).from_con("[1 2 3]").should eq [1, 2, 3]
  end

  it "does Array(Int64)#from_con" do
    Array(Int64).from_con("[1 2 3]").should eq([1, 2, 3])
  end

  it "does Array(Float32)#from_con" do
    Array(Float32).from_con("[1.5 2 3.5]").should eq([1.5, 2.0, 3.5])
  end

  it "does Array(Float64)#from_con" do
    Array(Float64).from_con("[1.5 2 3.5]").should eq([1.5, 2, 3.5])
  end

  it "does Hash(String, String)#from_con" do
    Hash(String, String).from_con(%(foo "x" bar "y")).should eq({"foo" => "x", "bar" => "y"})
  end

  it "does Hash(String, Int32)#from_con" do
    Hash(String, Int32).from_con(%({foo 1 bar 2})).should eq({"foo" => 1, "bar" => 2})
  end

  it "raises an error Hash(String, Int32)#from_con with null value" do
    expect_raises(CON::ParseException) do
      Hash(String, Int32).from_con(%(foo 1 bar 2 baz nil))
    end
  end

  it "does for Array(Int32) from IO" do
    io = IO::Memory.new "[1 2 3]"
    Array(Int32).from_con(io).should eq([1, 2, 3])
  end

  it "does for tuple" do
    tuple = Tuple(Int32, String).from_con %([1 "hello"] )
    tuple.should eq({1, "hello"})
    tuple.should be_a Tuple(Int32, String)
  end

  it "does for named tuple" do
    tuple = NamedTuple(x: Int32, y: String).from_con(%({y "hello" x 1}))
    tuple.should eq({x: 1, y: "hello"})
    tuple.should be_a(NamedTuple(x: Int32, y: String))
  end

  it "does for BigInt" do
    big = BigInt.from_con("\"123456789123456789123456789123456789123456789\"")
    big.should be_a(BigInt)
    big.should eq(BigInt.new("123456789123456789123456789123456789123456789"))
  end

  it "does for BigFloat" do
    big = BigFloat.from_con("\"1234.567891011121314\"")
    big.should be_a(BigFloat)
    big.should eq(BigFloat.new("1234.567891011121314"))
  end

  it "does for BigFloat from int" do
    big = BigFloat.from_con("1234")
    big.should be_a(BigFloat)
    big.should eq(BigFloat.new("1234"))
  end

  it "does for UUID (hyphenated)" do
    uuid = UUID.from_con("\"ee843b26-56d8-472b-b343-0b94ed9077ff\"")
    uuid.should be_a(UUID)
    uuid.should eq(UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff"))
  end

  it "does for UUID (hex)" do
    uuid = UUID.from_con("\"ee843b2656d8472bb3430b94ed9077ff\"")
    uuid.should be_a(UUID)
    uuid.should eq(UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff"))
  end

  it "does for UUID (urn)" do
    uuid = UUID.from_con("\"urn:uuid:ee843b26-56d8-472b-b343-0b94ed9077ff\"")
    uuid.should be_a(UUID)
    uuid.should eq(UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff"))
  end

  it "does for BigDecimal from int" do
    big = BigDecimal.from_con("1234")
    big.should be_a(BigDecimal)
    big.should eq(BigDecimal.new("1234"))
  end

  it "does for BigDecimal from float" do
    big = BigDecimal.from_con("1234.05")
    big.should be_a(BigDecimal)
    big.should eq(BigDecimal.new("1234.05"))
  end

  it "does for Enum with number" do
    CONSpecEnum.from_con("1").should eq(CONSpecEnum::One)

    expect_raises(Exception, "Unknown enum CONSpecEnum value: 3") do
      CONSpecEnum.from_con("3")
    end
  end

  it "does for Enum with string" do
    CONSpecEnum.from_con(%("One")).should eq(CONSpecEnum::One)

    expect_raises(ArgumentError, "Unknown enum CONSpecEnum value: Three") do
      CONSpecEnum.from_con(%("Three"))
    end
  end

  it "deserializes union" do
    Array(Int64 | String).from_con(%([1 "hello"])).should eq([1, "hello"])
  end

  it "deserializes union with bool" do
    Union(Bool, Array(Int64)).from_con(%(true)).should be_true
  end

  it "deserializes a deep union" do
    Array(Int64 | Hash(String, Array(Float64))).from_con(%([1 {hello [1.1]}])).should eq([1, {"hello" => [1.1]}])
  end

  it "deserializes union with Float64" do
    Union(Float64, Int64).from_con(%(1)).should eq(1)
    Union(Float64, Int64).from_con(%(1.23)).should eq(1.23)
  end

  it "deserializes Time" do
    Time.from_con(%("2016-11-16T09:55:48-03:00")).to_utc.should eq(Time.utc(2016, 11, 16, 12, 55, 48))
    Time.from_con(%("2016-11-16T09:55:48-0300")).to_utc.should eq(Time.utc(2016, 11, 16, 12, 55, 48))
    Time.from_con(%("20161116T095548-03:00")).to_utc.should eq(Time.utc(2016, 11, 16, 12, 55, 48))
  end

  describe "parse exceptions" do
    it "has correct location when raises in NamedTuple#from_con" do
      ex = expect_raises(CON::ParseException) do
        Array({foo: Int32, bar: String}).from_con <<-CON
       [
       {"foo": 1}
       ]
       CON
      end
    end
  end
end
