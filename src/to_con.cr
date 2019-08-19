require "./builder"

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
    con.integer self
  end
end

struct Float
  def to_con(con : CON::Builder)
    con.float self
  end
end

struct Nil
  def to_con(con : CON::Builder)
    con.nil
  end
end

struct Bool
  def to_con(con : CON::Builder)
    con.bool self
  end
end

class String
  def to_con(con : CON::Builder)
    con.string self
  end
end

struct Symbol
  def to_con(con : CON::Builder)
    con.string to_s
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
    con.hash(new_line: false) do
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
    con.hash(new_line: false) do
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
