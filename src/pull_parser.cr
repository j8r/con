require "./lexer.cr"

class CON::PullParser
  property max_nesting : Int32 = 512
  @nest = 0
  @lexer : CON::Lexer::FromIO | CON::Lexer::FromString

  # Skips all subdata of a key
  def skip_value
    @lexer.nobuffer = true
    case value = read_value_unchecked
    when Token::BeginHash  then skip_hash
    when Token::BeginArray then skip_array
    when Type # good

    else expect value, Union(Type | Token::BeginHash | Token::BeginArray)
    end
    @lexer.nobuffer = false
    value
  end

  # Skips array elements
  private def skip_array
    read_array_unchecked do |element|
      case element
      when Token::BeginHash  then skip_hash
      when Token::BeginArray then skip_array
      end
    end
  end

  # Skips hash key/values
  private def skip_hash
    read_hash_unchecked do |key|
      skip_value
    end
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

  def read_key : String
    expect @lexer.next_key, String
  end

  def read_key_unchecked : String | Token | Nil
    @lexer.next_key
  end

  def read_value : Type
    expect @lexer.next_value, Type
  end

  def read_value_unchecked : Type | Token
    @lexer.next_value
  end

  def read_array_unchecked(&block)
    increment_nest
    while true
      case value = @lexer.next_value
      when Token::EndArray            then break
      when Token::EOF, Token::EndHash then unexpected_token value
      else                                 yield value
      end
    end
    @nest -= 1
  end

  def read_array(&block)
    increment_nest
    expect @lexer.next_value, Token::BeginArray
    yield
    expect @lexer.next_value, Token::EndArray
    @nest -= 1
  end

  def read_hash_unchecked(&block)
    increment_nest
    while true
      case key = @lexer.next_key
      when String         then yield key
      when Token::EndHash then break
      else                     expect key, String
      end
    end
    @nest -= 1
  end

  def read_hash(&block)
    expect @lexer.next_key, Token::BeginHash
    read_hash_unchecked do |key|
      yield key
    end
  end

  def read_document(&block)
    case key = @lexer.next_key
    when Token::BeginHash then read_hash_unchecked { |key| yield key }
    when String
      increment_nest
      yield key
      while true
        case key = @lexer.next_key
        when String     then yield key
        when Token::EOF then return
        else                 expect key, String
        end
      end
      @nest -= 1
    when Token::EOF then return
    else                 expect key, Union(Token::BeginHash | String | Token::EOF)
    end
  end

  def expect(value, kind : T.class) forall T
    type_error(value, kind) if !value.is_a? T
    value
  end

  macro expect(value, kind)
    case %value = {{value}}
    when {{kind}}   then %value
    else                 type_error %value, {{kind}}
    end
  end

  def type_error(value, kind)
    parse_exception "Expected #{kind}, got #{value.class} (#{value.inspect})"
  end

  private def increment_nest
    if (@nest += 1) > @max_nesting
      parse_exception "Nesting of #{@nest} is too deep"
    end
  end

  protected def unexpected_token(token)
    parse_exception "Unexpected token: #{token}"
  end

  private def parse_exception(msg)
    raise ParseException.new(msg, @lexer.line_number, @lexer.column_number)
  end
end
