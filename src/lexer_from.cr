struct CON::Lexer::FromIO
  include Main

  def initialize(@io : IO)
    @current_char = @io.read_char || '\0'
  end

  def next_char : Char
    @current_char = @io.read_char || '\0'
  end

  def consume_string
    consume_string_with_buffer
  end

  def consume_key
    consume_key_with_buffer
  end
end

struct CON::Lexer::FromString
  include Main

  def initialize(string : String)
    @reader = Char::Reader.new string
    @current_char = @reader.current_char
  end

  def next_char : Char
    @column_number += 1
    @current_char = @reader.next_char
  end

  # Consume a string by remembering the start position of it and then
  # doing a substring of the original string.
  # If we find an escape sequence (\) we can't do that anymore so we
  # go through a slow path where we accumulate everything in a buffer
  # to build the resulting string.
  private def consume_string
    start_pos = @reader.pos
    while next_char
      case @current_char
      when '\\'
        @buffer.write slice_range(start_pos, @reader.pos)
        return consume_string_with_buffer
      when '"'  then next_char; break
      when '\0' then return Token::EOF
      end
    end

    @string_pool.get(@reader.string.to_unsafe + start_pos, @reader.pos - start_pos - 1) if !@skip
  end

  private def consume_key
    start_pos = @reader.pos
    while true
      case @current_char
      when '\\'
        @buffer.write slice_range(start_pos, @reader.pos)
        return consume_key_with_buffer
      when ' ', '\n', '\t', '\r', '[', '{' then break
      when '\0'                            then return Token::EOF
      end
      next_char
    end
    @string_pool.get(@reader.string.to_unsafe + start_pos, @reader.pos - start_pos) if !@skip
  end

  def string_range(start_pos, end_pos)
    @reader.string.byte_slice(start_pos, end_pos - start_pos)
  end

  def slice_range(start_pos, end_pos)
    @reader.string.to_slice[start_pos, end_pos - start_pos]
  end
end
