require "spec"
require "../src/lexer"

private def it_lexes_key(string, value, file = __FILE__, line = __LINE__)
  it "lexes #{string} from string", file, line do
    lexer = CON::Lexer::FromString.new string
    lexer.next_key.should eq value
  end

  it "lexes #{string} from IO", file, line do
    lexer = CON::Lexer::FromIO.new IO::Memory.new(string)
    lexer.next_key.should eq value
  end
end

private def it_lexes_value(string, value)
  it "lexes #{string} from String", __FILE__, __LINE__ do
    lexer = CON::Lexer::FromString.new string
    lexer.next_value.should eq value
  end

  it "lexes #{string} from IO", __FILE__, __LINE__ do
    lexer = CON::Lexer::FromIO.new IO::Memory.new(string)
    lexer.next_value.should eq value
  end
end

describe CON::Lexer::Main do
  it_lexes_key "", CON::Token::EOF
  it_lexes_key "{", CON::Token::BeginHash
  it_lexes_key "}", CON::Token::EndHash
  it_lexes_key "[", CON::Token::BeginArray
  it_lexes_key "]", CON::Token::EndArray
  it_lexes_key "key ", "key"
  it_lexes_key "key # comment", "key"
  it_lexes_value "{", CON::Token::BeginHash
  it_lexes_value "}", CON::Token::EndHash
  it_lexes_value "[", CON::Token::BeginArray
  it_lexes_value "]", CON::Token::EndArray
  it_lexes_value " \n\t\r nil # comment", nil
  it_lexes_value "true", true
  it_lexes_value "false", false
  it_lexes_value "nil", nil
  it_lexes_value "\"\"", ""
  it_lexes_value "\"hello\"", "hello"
  it_lexes_value "\"hello\\\"world\"", "hello\"world"
  it_lexes_value "\"hello\\\\world\"", "hello\\world"
  it_lexes_value "\"hello\\/world\"", "hello/world"
  it_lexes_value "\"hello\\bworld\"", "hello\bworld"
  it_lexes_value "\"hello\\fworld\"", "hello\fworld"
  it_lexes_value "\"hello\\nworld\"", "hello\nworld"
  it_lexes_value "\"hello\\rworld\"", "hello\rworld"
  it_lexes_value "\"hello\\tworld\"", "hello\tworld"
  it_lexes_value "0", 0
  it_lexes_value "1", 1
  it_lexes_value "1234", 1234
  it_lexes_value "0.123", 0.123
  it_lexes_value "1234.567", 1234.567
  it_lexes_value "9.91343313498688", 9.91343313498688
  it_lexes_value "-1", -1
  it_lexes_value "-1.23", -1.23
  it_lexes_value "1000000000000000000.0", 1000000000000000000.0
  it_lexes_value "6000000000000000000.0", 6000000000000000000.0
  it_lexes_value "9000000000000000000.0", 9000000000000000000.0
  it_lexes_value "9876543212345678987654321.0", 9876543212345678987654321.0
  it_lexes_value "10.100000000000000000000", 10.1
end
