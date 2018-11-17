class Object
  def to_con
    String.build do |str|
      to_con str
    end
  end

  def to_con(io : IO)
    to_con(CON::Builder.new io)
  end

  def to_pretty_con(indent : String = "  ")
    String.build do |str|
      to_pretty_con str, indent
    end
  end

  def to_pretty_con(io : IO, indent : String = "  ")
    to_con(CON::Builder.new io, indent)
  end
end

struct Int
  def to_con(con : CON::Builder)
    con.io << self
  end
end

struct Float
  def to_con(con : CON::Builder)
    con.io << self
  end
end

struct Nil
  def to_con(con : CON::Builder)
    con.io << "nil"
  end
end

struct Bool
  def to_con(con : CON::Builder)
    con.io << self
  end
end

class String
  def to_con_key(con : CON::Builder)
    string = self
    start_pos = 0
    reader = Char::Reader.new(string)
    while reader.has_next?
      case char = reader.current_char
      when '\\' then escape = "\\\\"
      when ' '  then escape = "\\ "
      when '\b' then escape = "\\b"
      when '\f' then escape = "\\f"
      when '\n' then escape = "\\n"
      when '\r' then escape = "\\r"
      when '\t' then escape = "\\t"
      when '{'  then escape = "\\{"
      when '}'  then escape = "\\}"
      when '['  then escape = "\\["
      when ']'  then escape = "\\]"
      else
        reader.next_char
        next
      end
      con.io.write string.to_slice[start_pos, reader.pos - start_pos]
      con.io << escape
      reader.next_char
      start_pos = reader.pos
    end
    con.io.write string.to_slice[start_pos, reader.pos - start_pos]
  end

  def to_con(con : CON::Builder)
    string = self
    con.io << '"'
    start_pos = 0
    reader = Char::Reader.new(string)

    while reader.has_next?
      case char = reader.current_char
      when '\\' then escape = "\\\\"
      when '"'  then escape = "\\\""
      when '\b' then escape = "\\b"
      when '\f' then escape = "\\f"
      when '\n' then escape = "\\n"
      when '\r' then escape = "\\r"
      when '\t' then escape = "\\t"
      else
        reader.next_char
        next
      end

      con.io.write string.to_slice[start_pos, reader.pos - start_pos]
      con.io << escape
      reader.next_char
      start_pos = reader.pos
    end
    con.io.write string.to_slice[start_pos, reader.pos - start_pos]
    con.io << '"'
  end
end

struct Symbol
  def to_con(con : CON::Builder)
    to_s.to_con con
  end
end

class Array
  def to_con(con : CON::Builder)
    con.array do
      each do |element|
        con.value element
      end
    end
  end
end

struct Set
  def to_con(con : CON::Builder)
    con.array do
      each do |element|
        con.value element
      end
    end
  end
end

class Hash
  def to_con(con : CON::Builder)
    con.hash do
      each do |key, value|
        con.field key, value
      end
    end
  end
end

struct Tuple
  def to_con(con : CON::Builder)
    con.array do
      {% for i in 0...T.size %}
      con.value self[{{i}}]
      {% end %}
    end
  end
end

struct NamedTuple
  def to_con(con : CON::Builder)
    con.hash do
      {% for key in T.keys %}
        con.field({{key.stringify}}, self[{{key.symbolize}}])
      {% end %}
    end
  end
end

# See https://github.com/crystal-lang/crystal/blob/master/src/json/to_json.cr
struct Time
  def to_con(con : CON::Builder)
    Format::RFC_3339.format(self, fraction_digits: 0).to_con con
  end

  struct Format
    def to_con(value : Time, con : CON::Builder)
      format(value).to_con(con)
    end
  end

  module EpochConverter
    def self.to_con(value : Time, con : CON::Builder)
      value.to_unix.to_con con
    end
  end

  module EpochMillisConverter
    def self.to_con(value : Time, con : CON::Builder)
      value.to_unix_ms.to_con con
    end
  end
end

struct Enum
  def to_con(con : CON::Builder)
    value.to_con con
  end
end

struct JSON::Any
  def to_con(con : CON::Builder)
    @raw.to_con con
  end
end
