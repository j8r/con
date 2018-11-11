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
    assert_built(" nil") do
      value nil
    end
  end
  it "writes bool" do
    assert_built(" true") do
      value true
    end
  end

  it "writes integer" do
    assert_built(" 123") do
      value 123
    end
  end

  it "writes float" do
    assert_built(" 123.45") do
      value 123.45
    end
  end

  it "writes string" do
    assert_built(%< "hello">) do
      value "hello"
    end
  end
  # it "errors on nan" do
  # con = CON::Builder.new(IO::Memory.new)
  # con.start_document
  # expect_raises CON::Error, "NaN not allowed in CON" do
  # con.number(0.0/0.0)
  # end
  # end

  # it "errors on infinity" do
  # con = CON::Builder.new(IO::Memory.new)
  # con.start_document
  # expect_raises CON::Error, "Infinity not allowed in CON" do
  # con.number(1.0/0.0)
  # end
  # end

  it "writes string with controls and slashes " do
    assert_built(" \" \\\" \\\\ \\b \\f \\n \\r \\t \\\"\"") do
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

  it "writes object" do
    assert_built(%<foo 1 bar 2>) do
      hash do
        field "foo", 1
        field "bar", 2
      end
    end
  end

  it "writes nested object" do
    assert_built(%<foo{bar 2 baz 3} another{baz 3}>) do
      hash do
        hash "foo" do
          field "bar", 2
          field "baz", 3
        end
        hash "another" do
          field "baz", 3
        end
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

  it "writes object with indent" do
    assert_built(%<  foo 1\n  bar 2\n>, "  ") do |con|
      hash do
        field "foo", 1
        field "bar", 2
      end
    end
  end

  it "writes empty array with indent" do
    assert_built(%<[\n]>, "  ") do |con|
      array do
      end
    end
  end

  it "writes empty object with indent" do
    assert_built(%<>, "  ") do |con|
      hash do
      end
    end
  end

  it "writes nested array" do
    assert_built(%<[[\n]\n]>, "  ") do |con|
      array do
        array do
        end
      end
    end
  end

  it "writes object with array and indent" do
    assert_built(%<foo {\n[\n  1\n]  }>, "  ") do |con|
      hash "foo" do
        array do
          value 1
        end
      end
    end
  end

  it "writes object with array, indent, values and field" do
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

  it "writes field with scalar in object" do
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

  it "writes field with arbitrary value in object" do
    assert_built(%<hash {hash "value"} object {int 12}>) do
      hash do
        field "hash", {"hash" => "value"}
        field "object", TestObject.new
      end
    end
  end
end
