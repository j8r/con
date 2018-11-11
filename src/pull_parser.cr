require "./lexer.cr"

class CON::PullParser
  @lexer : CON::Lexer::FromIO | CON::Lexer::FromString

  # Skips all subdata of a key
  def skip
    @lexer.nobuffer = true
    case value = read_value
    when Token::BeginHash  then read_hash_unchecked { |key| skip }
    when Token::BeginArray then read_array_unchecked { |element| skip }
    when Type              then return
    else                        expect value, Union(Type | Token::BeginHash | Token::BeginArray)
    end
    @lexer.nobuffer = false
  end

  def line_number : Int32
    @lexer.line_number
  end

  def column_number : Int32
    @lexer.column_number
  end

  def initialize(string : String)
    @lexer = CON::Lexer::FromString.new string
  end

  def initialize(io : IO)
    @lexer = CON::Lexer::FromIO.new io
  end

  def next_key_unchecked : String | Token | Nil
    @lexer.next_key
  end

  def read_key : String
    expect @lexer.next_key, String
  end

  def read_value : Type | Token
    @lexer.next_value
  end

  def read_array_unchecked(&block)
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

  def read_hash_unchecked(&block)
    loop_until Token::EndHash
  end

  def read_document(&block)
    case key = @lexer.next_key
    when Token::BeginHash then read_hash_unchecked { |key| yield key }
    when String           then yield key; loop_until Token::EOF
    when Token::EOF       then return
    else                       expect key, Union(Token::BeginHash | String | Token::EOF)
    end
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
    case _value = {{value}}
    when {{kind}}   then _value
    else                 parse_exception "Expected {{kind}}, got #{_value.class} (#{_value.inspect})"
    end
  end

  protected def unexpected_token
    parse_exception "Unexpected token: #{token}"
  end

  private def parse_exception(msg)
    raise ParseException.new(msg, @lexer.line_number, @lexer.column_number)
  end
end
