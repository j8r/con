require "spec"
require "../src/builder"

private def assert_built(expected, indent = nil)
  string = CON.build(indent) do |con|
    with con yield con
  end
  string.should eq(expected)
end

private class TestObject
  def to_con(builder)
    {"int" => 12}.to_con(builder)
  end
end

describe CON::Builder do
  it "writes null" do
    assert_built("nil") do
      value nil
    end
  end
  it "writes bool" do
    assert_built("true") do
      value true
    end
  end

  it "writes integer" do
    assert_built("123") do
      value 123
    end
  end

  it "writes float" do
    assert_built("123.45") do
      value 123.45
    end
  end

  it "writes string" do
    assert_built(%<"hello">) do
      value "hello"
    end
  end

  it "writes string with controls and slashes " do
    assert_built("\" \\\" \\\\ \\b \\f \\n \\r \\t \\\"\"") do
      value %< \" \\ \b \f \n \r \t ">
    end
  end

  it "writes array" do
    assert_built(%<[1 "hello" true]>) do
      array do
        value 1
        value "hello"
        value true
      end
    end
  end

  it "writes nested array" do
    assert_built(%<[1["hello" true] 2]>) do
      array do
        value 1
        array do
          value "hello"
          value true
        end
        value 2
      end
    end
  end

  it "writes hash" do
    assert_built(%<foo 1 bar 2>) do
      hash do
        field "foo", 1
        field "bar", 2
      end
    end
  end

  it "writes nested hash in root" do
    assert_built(%<foo{bar 2 baz 3} another{baz 3}>) do
      hash "foo" do
        field "bar", 2
        field "baz", 3
      end
      hash "another" do
        field "baz", 3
      end
    end
  end

  it "writes array with indent" do
    assert_built(%<[\n\t1\n\t2\n\t3\n]>, "\t") do |con|
      array do
        value 1
        value 2
        value 3
      end
    end
  end

  it "writes nested hash with indent" do
    assert_built(%<foo 1\nbar {\n  foobar 2\n  sub {\n    key nil\n  }\n}\n>, "  ") do |con|
      hash do
        field "foo", 1
        hash "bar" do
          field "foobar", 2
          hash "sub" do
            field "key", nil
          end
        end
      end
    end
  end

  it "writes empty array with indent" do
    assert_built(%<[\n]>, "  ") do |con|
      array do
      end
    end
  end

  it "writes empty hash with indent" do
    assert_built(%<>, "  ") do |con|
      hash do
      end
    end
  end

  it "writes nested array with indent" do
    assert_built(%<[[\n  ]\n]>, "  ") do |con|
      array do
        array do
        end
      end
    end
  end

  it "writes document with array and indent" do
    assert_built(%<[\n  1\n]>, "  ") do |con|
      hash do
        array do
          value 1
        end
      end
    end
  end

  it "writes hash with array, indent, values and field" do
    assert_built(%<name "foo" values[1 2 3]>) do
      hash do
        field "name", "foo"
        array "values" do
          value 1
          value 2
          value 3
        end
      end
    end
  end

  it "writes field with scalar in hash" do
    assert_built(%<int 42 float 0.815 null nil bool true string "string">) do
      hash do
        field "int", 42
        field "float", 0.815
        field "null", nil
        field "bool", true
        field "string", "string"
      end
    end
  end

  it "writes field with arbitrary value in hash" do
    assert_built(%<hash {hash "value"} hash {int 12}>) do
      hash do
        field "hash", {"hash" => "value"}
        field "hash", TestObject.new
      end
    end
  end

  it "errors on max nesting (array)" do
    builder = CON::Builder.new IO::Memory.new
    builder.max_nesting = 3
    builder.array do
      builder.array do
        builder.array do
        end
      end
    end

    expect_raises(CON::Builder::Error, "Nesting of 4 is too deep") do
      builder.array do
      end
    end
  end

  it "errors on max nesting (object)" do
    builder = CON::Builder.new IO::Memory.new
    builder.max_nesting = 3
    builder.hash "a" do
      builder.hash "a" do
        builder.hash "a" do
        end
      end
    end

    expect_raises(CON::Builder::Error, "Nesting of 4 is too deep") do
      builder.hash "a" do
      end
    end
  end
end
