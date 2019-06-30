require "string_pool"

module CON
  alias Type = Bool | Float64 | Int64 | String | Nil

  def self.parse(source : String | IO) : Any
    CON::Any.from_con CON::PullParser.new(source)
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
  @buffer : IO::Memory? = IO::Memory.new
  @string_pool = StringPool.new
  getter line_number = 1
  getter column_number = 1
  getter current_char : Char

  def nobuffer=(nobuffer : Bool)
    @buffer = nobuffer ? nil : IO::Memory.new
  end

  def next_value : Type | CON::Token
    skip_whitespaces_and_comments
    @buffer.try &.clear
    value = case @current_char
            when '"'      then next_char; consume_string
            when '['      then next_char; Token::BeginArray
            when ']'      then next_char; Token::EndArray
            when '{'      then next_char; Token::BeginHash
            when '}'      then next_char; Token::EndHash
            when 't'      then consume_true
            when 'f'      then consume_false
            when 'n'      then consume_nil
            when '-'      then consume_int(negative: true)
            when '0'..'9' then consume_int
            when '\0'     then Token::EOF
            else               raise "Unknown char: '#{@current_char}'"
            end
    @column_number = 1
    value
  end

  def next_key : String | Nil | CON::Token
    skip_whitespaces_and_comments
    @buffer.try &.clear
    case @current_char
    when '{'  then next_char; return Token::BeginHash
    when '}'  then next_char; return Token::EndHash
    when '['  then next_char; return Token::BeginArray
    when ']'  then next_char; return Token::EndArray
    when '\0' then return Token::EOF
    end
    consume_key
  end

  private def consume_key_with_buffer
    while true
      case @current_char
      when ' ', '\n', '\t', '\r', '[', '{'
        if buffer = @buffer
          return @string_pool.get(buffer)
        end
      when '\\' then consume_escape
      when '\0' then return Token::EOF
      else           @buffer.try &.<< @current_char
      end
      next_char
    end
  end

  private def consume_string_with_buffer
    while true
      case @current_char
      when '"'  then next_char; return @buffer.try &.to_s
      when '\\' then consume_escape
      when '\0' then return Token::EOF
      else           @buffer.try &.<< @current_char
      end
      next_char
    end
  end

  private def consume_float(integer : Int64, digits : Int32) : Float64
    divisor = 1_i64
    while next_char
      case @current_char
      when '0'..'9'
        if buffer = @buffer
          integer *= 10
          integer += @current_char - '0'
          divisor *= 10
          digits += 1
          buffer << @current_char
        end
      when '\0', ' ', '\n', '\t', '\r', '[', ']', '{', '}' then break
      else                                                      unexpected_char "float"
      end
    end
    if digits > 17 && (buffer = @buffer)
      buffer.to_s.to_f64
    else
      integer.to_f64 / divisor
    end
  end

  private def consume_int(negative : Bool = false) : Int64 | Float64
    digits = 0
    integer = negative ? 0_i64 : (@current_char - '0').to_i64
    @buffer.try &.<< @current_char
    while next_char
      case @current_char
      when '0'..'9'
        if buffer = @buffer
          integer *= 10
          integer += @current_char - '0'
          digits += 1
          buffer << @current_char
        end
      when '\0', ' ', '\n', '\t', '\r', '[', ']', '{', '}' then break
      when '.'
        @buffer.try &.<< @current_char
        return (negative ? -consume_float(integer, digits) : consume_float(integer, digits))
      else unexpected_char "int"
      end
    end
    if digits > 17 && (buffer = @buffer)
      buffer.to_s.to_i64
    else
      negative ? -integer : integer
    end
  end

  private def consume_escape
    @buffer.try &.<< case next_char
    when 'b' then '\b'
    when 'f' then '\f'
    when 'n' then '\n'
    when 'r' then '\r'
    when 't' then '\t'
    else          @current_char
    end
  end

  private def skip_whitespaces_and_comments
    while true
      case @current_char
      when ' ', '\t', '\r' then next_char
      when '\n'            then next_char; @line_number += 1
      when '#'             then skip_comments
      else                      break
      end
    end
  end

  private def skip_comments
    # Skip comments
    while true
      case next_char
      when '\n', '\0' then break
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
