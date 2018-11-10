require "string_pool"

module CON
  alias Type = Bool | Float64 | Int64 | String | Nil

  def self.parse(source : String | IO) : Any
    CON::Any.new CON::PullParser.new(source)
  end

  # Generic CON error.
  class Error < Exception
  end

  # Exception thrown on a CON parse error.
  class ParseException < Error
    getter line_number : Int32
    getter column_number : Int32

    def initialize(message, @line_number, @column_number, cause = nil)
      super "#{message} at #{@line_number}:#{@column_number}", cause
    end
  end

  enum Token
    BeginArray
    EndArray
    BeginHash
    EndHash
    EOF
  end
end

module CON::Lexer::Main
  struct Null
    def <<(value)
    end

    def clear
    end
  end

  @buffer : IO::Memory = IO::Memory.new
  @string_pool = StringPool.new
  getter line_number = 1
  getter column_number = 1
  getter current_char : Char
  getter skip : Bool = false

  def skip=(@skip : Bool)
    @buffer = @skip ? Null.new : IO::Memory.new
  end

  def next_value : Type | CON::Token
    skip_whitespaces_and_comments
    case @current_char
    when '"'                                                   then next_char; consume_string
    when '['                                                   then next_char; Token::BeginArray
    when ']'                                                   then next_char; Token::EndArray
    when '{'                                                   then next_char; Token::BeginHash
    when '}'                                                   then next_char; Token::EndHash
    when 't'                                                   then consume_true
    when 'f'                                                   then consume_false
    when 'n'                                                   then consume_nil
    when '\0'                                                  then Token::EOF
    when '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' then consume_int
    else                                                            raise "Unknown char: '#{@current_char}'"
    end
  end

  def next_key : String | Nil | CON::Token
    skip_whitespaces_and_comments
    case @current_char
    when '{'  then next_char; return Token::BeginHash
    when '}'  then next_char; return Token::EndHash
    when '['  then next_char; return Token::BeginArray
    when ']'  then next_char; return Token::EndArray
    when '\0' then return Token::EOF
    end
    @column_number = 1
    consume_key
  end

  private def consume_key_with_buffer
    while true
      case @current_char
      when '\\'                            then consume_escape
      when ' ', '\n', '\t', '\r', '[', '{' then return build_string if !@skip
      when '\0'                            then return Token::EOF
      else                                      @buffer << @current_char
      end
      next_char
    end
  end

  private def consume_string_with_buffer
    while true
      case @current_char
      when '\\' then consume_escape
      when '"'  then next_char; return build_string if !@skip
      when '\0' then return Token::EOF
      else           @buffer << @current_char
      end
      next_char
    end
  end

  private def consume_float
    @buffer << @current_char
    while next_char
      case @current_char
      when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' then @buffer << @current_char
      when '\0', ' ', '\n', '\t', '\r', ']', '}'            then return build_string.to_f64 if !@skip
      else                                                       unexpected_char "float"
      end
    end
  end

  private def consume_int
    @buffer << @current_char
    while next_char
      case @current_char
      when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' then @buffer << @current_char
      when '\0', ' ', '\n', '\t', '\r', ']', '}'            then return build_string.to_i64 if !@skip
      when '.'                                              then return consume_float
      else                                                       unexpected_char "int"
      end
    end
  end

  private def consume_escape
    @buffer << case next_char
    when 'b' then '\b'
    when 'f' then '\f'
    when 'n' then '\n'
    when 'r' then '\r'
    when 't' then '\t'
    else          @current_char
    end
  end

  private def build_string : String
    string = @string_pool.get(@buffer)
    @buffer.clear
    string
  end

  private def skip_whitespaces_and_comments
    while true
      case @current_char
      when ' ', '\t', '\r' then next_char
      when '\n'            then next_char; @line_number += 1
      when '#'
        # Skip comments
        while next_char != '\n'
        end
      else break
      end
    end
  end

  private def consume_true : Bool
    if next_char == 'r' && next_char == 'u' && next_char == 'e'
      next_char
      return true
    end
    unexpected_char "true"
  end

  private def consume_false : Bool
    if next_char == 'a' && next_char == 'l' && next_char == 's' && next_char == 'e'
      next_char
      return false
    end
    unexpected_char "false"
  end

  private def consume_nil : Nil
    if next_char == 'i' && next_char == 'l'
      next_char
      return
    end
    unexpected_char "nil"
  end

  private def unexpected_char(type : String)
    raise "Unexpected char for `#{type}`: '#{@current_char}'"
  end

  private def raise(msg)
    ::raise ParseException.new(msg, @line_number, @column_number)
  end
end

require "./lexer_from"
