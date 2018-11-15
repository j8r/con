require "spec"
require "../src/pull_parser"

def assert_pull_parse_value(string : String, expected)
  it "reads value '#{string}'" do
    pull_parser = CON::PullParser.new string
    pull_parser.read_value.should eq expected
  end
end

private def assert_pull_parse_skip_value(string : String)
  it "parses '#{string}'" do
    pull_parser = CON::PullParser.new string
    pull_parser.skip_value
    # Nothing remains to parse
    pull_parser.read_value.should eq CON::Token::EOF
  end
end

private def assert_pull_parse_error(string)
  it "errors on '#{string}'" do
    expect_raises CON::ParseException do
      pull_parser = CON::PullParser.new string
      pull_parser.skip_value
    end
  end
end

describe CON::PullParser do
  assert_pull_parse_value "nil", nil
  assert_pull_parse_value "false", false
  assert_pull_parse_value "true", true
  assert_pull_parse_value "1", 1
  assert_pull_parse_value "1.5", 1.5
  assert_pull_parse_value %("hello"), "hello"
  assert_pull_parse_value "[", CON::Token::BeginArray
  assert_pull_parse_value "]", CON::Token::EndArray
  assert_pull_parse_value "{", CON::Token::BeginHash
  assert_pull_parse_value "}", CON::Token::EndHash
  assert_pull_parse_value "# comment", CON::Token::EOF
  assert_pull_parse_value "# comment\nnil", nil
  assert_pull_parse_skip_value "[]"
  assert_pull_parse_skip_value "[[]]"
  assert_pull_parse_skip_value "[1]"
  assert_pull_parse_skip_value "[1.5]"
  assert_pull_parse_skip_value "[nil]"
  assert_pull_parse_skip_value "[true]"
  assert_pull_parse_skip_value "[false]"
  assert_pull_parse_skip_value %(["hello"])
  assert_pull_parse_skip_value "[1 2]"
  assert_pull_parse_skip_value "{}"
  assert_pull_parse_skip_value %({foo 1})
  assert_pull_parse_skip_value %({foo "bar"})
  assert_pull_parse_skip_value %({foo [1 2]})
  assert_pull_parse_skip_value %({foo 1 bar 2})
  assert_pull_parse_skip_value %({foo "foo1" bar "bar1"})
  assert_pull_parse_error "[,1]"
  assert_pull_parse_error "[}]"
  assert_pull_parse_error "["
  assert_pull_parse_error %({"foo",1})
  assert_pull_parse_error %({"foo"::1})
  assert_pull_parse_error %(["foo":1])
  assert_pull_parse_error %({"foo": []:1})
  assert_pull_parse_error "[[]"
  assert_pull_parse_error %({"foo": {})

  describe "skip" do
    [
      {"nil", "nil"},
      {"bool", "false"},
      {"int", "3"},
      {"float", "3.5"},
      {"string", %("hello")},
      {"array", %([10 20 [30] [40]])},
      {"object", %({foo [1 2] bar {baz [3]}})},
    ].each do |(desc, obj)|
      it "#{desc}" do
        pull = CON::PullParser.new("[1 #{obj} 2]")
        pull.read_array do
          pull.read_value.should eq 1
          pull.skip_value
          pull.read_value.should eq 2
        end
      end
    end
  end

  it "reads array" do
    pull = CON::PullParser.new(%([1]))
    pull.read_array do
      pull.read_value.should eq 1
    end
  end

  it "reads array with coments" do
    pull = CON::PullParser.new(%([1\n# some comments \n 2]))
    pull.read_array do
      pull.read_value.should eq 1
      pull.read_value.should eq 2
    end
  end

  it "reads hash" do
    pull = CON::PullParser.new(%({foo 1}))
    pull.read_hash do |key|
      key.should eq "foo"
      pull.read_value.should eq 1
    end
  end

  describe "document" do
    it "reads with brackets" do
      pull = CON::PullParser.new(%({foo 1}))
      pull.read_document do |key|
        key.should eq "foo"
        pull.read_value.should eq 1
      end
    end
    it "reads with coments" do
      pull = CON::PullParser.new(%(foo # comments\n1))
      pull.read_document do |key|
        key.should eq "foo"
        pull.read_value.should eq 1
      end
    end
  end

  ["1", "[1]", %({x [1]})].each do |value|
    it "yields all keys when skipping #{value}" do
      pull = CON::PullParser.new(%({foo #{value} bar 2}))
      pull.read_hash do |key|
        key.should_not be_empty
        pull.skip_value
      end
    end
  end
end
