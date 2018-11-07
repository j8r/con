require "spec"
require "../src/any"

describe CON::Any do
  describe "casts" do
    it "gets nil" do
      CON.parse("[nil]")[0].as_nil.should be_nil
    end

    it "gets bool" do
      CON.parse("[true]")[0].as_bool.should be_true
      CON.parse("[false]")[0].as_bool.should be_false
      CON.parse("[true]")[0].as_bool?.should be_true
      CON.parse("[false]")[0].as_bool?.should be_false
      CON.parse("[2]")[0].as_bool?.should be_nil
    end

    it "gets int32" do
      CON.parse("[123]")[0].as_i.should eq(123)
      CON.parse("[123]")[0].as_i?.should eq(123)
      CON.parse("[true]")[0].as_i?.should be_nil
    end

    it "gets int64" do
      CON.parse("[123456789123456]")[0].as_i64.should eq(123456789123456)
      CON.parse("[123456789123456]")[0].as_i64?.should eq(123456789123456)
      CON.parse("[true]")[0].as_i64?.should be_nil
    end

    it "gets float32" do
      CON.parse("[123.45]")[0].as_f32.should eq(123.45_f32)
      CON.parse("[123.45]")[0].as_f32?.should eq(123.45_f32)
      CON.parse("[true]")[0].as_f32?.should be_nil
    end

    it "gets float64" do
      CON.parse("[123.45]")[0].as_f.should eq(123.45)
      CON.parse("[123.45]")[0].as_f?.should eq(123.45)
      CON.parse("[true]")[0].as_f?.should be_nil
    end

    it "gets string" do
      CON.parse(%(["hello"]))[0].as_s.should eq("hello")
      CON.parse(%(["hello"]))[0].as_s?.should eq("hello")
      CON.parse("[true]")[0].as_s?.should be_nil
    end

    it "gets array" do
      CON.parse(%([1 2 3])).as_a.should eq([1, 2, 3])
      CON.parse(%([1 2 3])).as_a?.should eq([1, 2, 3])
      CON.parse("a true").as_a?.should be_nil
    end

    it "gets hash" do
      CON.parse(%({foo "bar"})).as_h.should eq({"foo" => "bar"})
      CON.parse(%({foo "bar"})).as_h.should eq({"foo" => "bar"})
      CON.parse(%({foo "bar"})).as_h?.should eq({"foo" => "bar"})
      CON.parse("[true]").as_h?.should be_nil
    end

    it "gets hash document" do
      CON.parse(%(foo "bar")).as_h.should eq({"foo" => "bar"})
      CON.parse(%(foo "bar")).as_h.should eq({"foo" => "bar"})
      CON.parse(%(foo "bar")).as_h?.should eq({"foo" => "bar"})
      CON.parse("[true]").as_h?.should be_nil
    end
  end

  describe "#size" do
    it "of array" do
      CON.parse("[1 2 3]").size.should eq(3)
    end

    it "of hash" do
      CON.parse(%({foo "bar"})).size.should eq(1)
    end
  end

  describe "#[]" do
    it "of array" do
      CON.parse("[1 2 3]")[1].raw.should eq(2)
    end

    it "of hash" do
      CON.parse(%({foo "bar"}))["foo"].raw.should eq("bar")
    end
  end

  describe "#[]?" do
    it "of array" do
      CON.parse("[1 2 3]")[1]?.not_nil!.raw.should eq(2)
      CON.parse("[1 2 3]")[3]?.should be_nil
      CON.parse("[true false]")[1]?.should eq false
    end

    it "of hash" do
      CON.parse(%({foo "bar"}))["foo"]?.not_nil!.raw.should eq("bar")
      CON.parse(%({foo "bar"}))["fox"]?.should be_nil
      CON.parse(%q<{foo false}>)["foo"]?.should eq false
    end
  end

  describe "#dig?" do
    it "gets the value at given path given splat" do
      obj = CON.parse(%({foo [1 {bar [2 3]}]}))

      obj.dig?("foo", 0).should eq(1)
      obj.dig?("foo", 1, "bar", 1).should eq(3)
    end

    it "returns nil if not found" do
      obj = CON.parse(%({foo [1 {bar [2 3]}]}))

      obj.dig?("foo", 10).should be_nil
      obj.dig?("bar", "baz").should be_nil
      obj.dig?("").should be_nil
    end
  end

  describe "dig" do
    it "gets the value at given path given splat" do
      obj = CON.parse(%({foo [1 {bar [2 3]}]}))

      obj.dig("foo", 0).should eq(1)
      obj.dig("foo", 1, "bar", 1).should eq(3)
    end

    it "raises if not found" do
      obj = CON.parse(%({foo [1 {bar [2 3]}]}))

      expect_raises Exception, %(Expected Hash for #[](key : String), not Array(CON::Any)) do
        obj.dig("foo", 1, "bar", "baz")
      end
      expect_raises KeyError, %(Missing hash key: "z") do
        obj.dig("z")
      end
      expect_raises KeyError, %(Missing hash key: "") do
        obj.dig("")
      end
    end
  end

  it "traverses big structure" do
    obj = CON.parse(%(foo [1 {bar [2 3]}]))
    obj["foo"][1]["bar"][1].as_i.should eq(3)
  end

  it "compares to other objects" do
    obj = CON.parse(%([1 2]))
    obj.should eq([1, 2])
    obj[0].should eq(1)
  end

  it "can compare with ===" do
    (1 === CON.parse("[1]")[0]).should be_truthy
  end

  it "exposes $~ when doing Regex#===" do
    (/o+/ === CON.parse(%(["foo"]))[0]).should be_truthy
    $~[0].should eq("oo")
  end

  it "dups" do
    any = CON.parse("[1 2 3]")
    any2 = any.dup
    any2.as_a.should_not be(any.as_a)
  end

  it "clones" do
    any = CON.parse("[[1] 2 3]")
    any2 = any.clone
    any2.as_a[0].as_a.should_not be(any.as_a[0].as_a)
  end
end
