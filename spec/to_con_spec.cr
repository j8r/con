require "spec"
require "big"
require "json"
require "../src/to_con"
require "../src/uuid"

enum CONSpecEnum
  Zero
  One
  Two
end

describe "to_con" do
  it "does for Nil" do
    nil.to_con.should eq "nil"
  end

  it "does for Bool" do
    true.to_con.should eq "true"
  end

  it "does for Int32" do
    1.to_con.should eq "1"
  end

  it "does for Float64" do
    1.5.to_con.should eq "1.5"
  end

  it "does for String" do
    "hello".to_con.should eq("\"hello\"")
  end

  it "does for String with quote" do
    "hel\"lo".to_con.should eq("\"hel\\\"lo\"")
  end

  it "does for String with slash" do
    "hel\\lo".to_con.should eq("\"hel\\\\lo\"")
  end

  it "does for String with control codes" do
    "\b".to_con.should eq("\"\\b\"")
    "\f".to_con.should eq("\"\\f\"")
    "\n".to_con.should eq("\"\\n\"")
    "\r".to_con.should eq("\"\\r\"")
    "\t".to_con.should eq("\"\\t\"")
  end

  it "does for String with control codes in a few places" do
    "\fab".to_con.should eq(%q("\fab"))
    "ab\f".to_con.should eq(%q("ab\f"))
    "ab\fcd".to_con.should eq(%q("ab\fcd"))
    "ab\fcd\f".to_con.should eq(%q("ab\fcd\f"))
    "ab\fcd\fe".to_con.should eq(%q("ab\fcd\fe"))
  end

  it "does for Array" do
    [1, 2, 3].to_con.should eq("[1 2 3]")
  end

  it "does for Set" do
    Set(Int32).new([1, 1, 2]).to_con.should eq("[1 2]")
  end

  it "does for Hash" do
    {"foo" => 1, "bar" => 2}.to_con.should eq %(foo 1 bar 2)
  end

  it "does for Hash with non-string keys" do
    {:foo => 1, :bar => 2}.to_con.should eq %(foo 1 bar 2)
  end

  it "does for Hash with newlines" do
    {"foo\nbar" => "baz\nqux"}.to_con.should eq %(foo\\nbar "baz\\nqux")
  end

  it "does for Tuple" do
    {1, "hello"}.to_con.should eq %([1 "hello"])
  end

  it "does for NamedTuple" do
    {x: 1, y: "hello"}.to_con.should eq %(x 1 y "hello")
  end

  it "does for Enum" do
    CONSpecEnum::One.to_con.should eq "1"
  end

  it "does for BigInt" do
    num = "123456789123456789123456789123456789123456789"
    BigInt.new(num).to_con.should eq num
  end

  it "does for BigFloat" do
    num = "1234.567891011121314"
    BigFloat.new(num).to_con.should eq num
  end

  it "does for UUID" do
    uuid = UUID.new("ee843b26-56d8-472b-b343-0b94ed9077ff")
    uuid.to_con.should eq("\"ee843b26-56d8-472b-b343-0b94ed9077ff\"")
  end
end

describe "to_pretty_con" do
  it "does for Nil" do
    nil.to_pretty_con.should eq "nil"
  end

  it "does for Bool" do
    true.to_pretty_con.should eq "true"
  end

  it "does for Int32" do
    1.to_pretty_con.should eq "1"
  end

  it "does for Float64" do
    1.5.to_pretty_con.should eq "1.5"
  end

  it "does for String" do
    "hello".to_pretty_con.should eq "\"hello\""
  end

  it "does for Array" do
    [1, 2, 3].to_pretty_con.should eq "[\n  1\n  2\n  3\n]"
  end

  it "does for nested Array" do
    [[1, 2, 3]].to_pretty_con.should eq "[\n  [\n    1\n    2\n    3\n  ]\n]"
  end

  it "does for empty Array" do
    ([] of Nil).to_pretty_con.should eq "[\n  \n]"
  end

  it "does for Hash" do
    {"foo" => 1, "bar" => 2}.to_pretty_con.should eq "foo 1\nbar 2\n"
  end

  it "does for nested Hash" do
    {"foo" => {"bar" => 1}}.to_pretty_con.should eq "foo {\n  bar 1\n}\n"
  end

  it "does for empty Hash" do
    ({} of Nil => Nil).to_pretty_con.should eq ""
  end

  it "does for Array with indent" do
    [1, 2, 3].to_pretty_con(indent: " ").should eq "[\n 1\n 2\n 3\n]"
  end

  it "does for nested Hash with indent" do
    {"foo" => {"bar" => 1}}.to_pretty_con(indent: " ").should eq "foo {\n bar 1\n}\n"
  end

  describe "Time" do
    it "#to_con" do
      Time.utc(2016, 11, 16, 12, 55, 48).to_con.should eq %("2016-11-16T12:55:48Z")
    end

    it "omit sub-second precision" do
      Time.utc(2016, 11, 16, 12, 55, 48, nanosecond: 123456789).to_con.should eq %("2016-11-16T12:55:48Z")
    end
  end

  it "JSON::Any#to_con" do
    any = JSON.parse(%({"key":"value","arr":[1,2]}))
    any.to_con.should eq(%(key "value" arr [1 2]))
  end
end
