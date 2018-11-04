require "./lexer.cr"

class CON::PullParser
  protected getter lexer : CON::Lexer::FromIO | CON::Lexer::FromString

  def initialize(string : String)
    @lexer = CON::Lexer::FromString.new string
  end

  def initialize(io : IO)
    @lexer = CON::Lexer::FromIO.new io
  end

  def read_key : String
    expect @lexer.next_key, String
  end

  def read_value
    @lexer.next_value
  end

  protected def read_array_unchecked(&block)
    while !(value = @lexer.next_value).is_a? Token::EndArray
      yield value
    end
  end

  def read_array(&block)
    expect @lexer.next_value, Token::BeginArray
    read_array_unchecked do |value|
      yield value
    end
  end

  protected def read_hash_unchecked(&block)
    loop_until Token::EndHash
  end

  def read_document(&block)
    loop_until Token::EOF
  end

  def read_hash(&block)
    expect @lexer.next_key, Token::BeginHash
    read_hash_unchecked do |key|
      yield key
    end
  end

  macro loop_until(kind)
    while true
      case key = @lexer.next_key
      when String     then yield key
      when {{kind}}   then break
      else                 expect key, String
      end
    end
  end

  macro expect(value, kind)
    case value = {{value}}
    when {{kind}}   then value
    else                 parse_exception "Expected {{kind}}, got #{value.inspect}"
    end
  end

  protected def unexpected_token
    parse_exception "Unexpected token: #{token}"
  end

  private def parse_exception(msg)
    raise ParseException.new(msg, @lexer.line_number, @lexer.column_number) # token.line_number, token.column_number)
  end
end
