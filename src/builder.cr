require "./to_con"

module CON
  struct Builder
    class Error < Exception
    end

    getter io : IO
    property max_nesting : Int32 = 99
    @nest : Int32 = 0
    @indent : String?
    @root_document = false
    @begin_hash = false
    @begin_array = false

    def initialize(@io : IO, @indent : String? = nil)
      # Not needed at the start/end of a document
      @root_document = true
      @begin_hash = true
    end

    protected def initialize(@io : IO, @indent : String?, @nest)
    end

    def field(key, value)
      if @begin_array
        raise Error.new("Can't use field inside an array")
      elsif @indent
        add_indent
      elsif @begin_hash
        @begin_hash = false
      else
        @io << ' '
      end
      key.to_s.to_con_key self
      @io << ' '
      value.to_con Builder.new(@io, @indent, @nest)
      @io << '\n' if @indent
    end

    def value(value)
      if @begin_hash && !@root_document
        raise Error.new("Can't use value inside a hash")
      elsif @begin_array
        @begin_array = false
      elsif @indent
        io << '\n'
        add_indent
      elsif @root_document
        @begin_hash = true
        @root_document = false
      else
        @io << ' '
      end
      value.to_con Builder.new(@io, @indent, @nest)
    end

    private def key(value)
      if @indent
        add_indent
      elsif !@begin_hash && !@begin_array
        @io << ' '
      end
      value.to_con_key self
      @io << ' ' if @indent
    end

    def array(key : String, &block)
      key(key)
      array { yield }
    end

    def array(&block)
      array_nest = @nest
      io << '['
      increment_nest
      if @indent
        @io << '\n'
        add_indent
      end
      @begin_array = true
      @begin_hash = false
      previous_root_document = @root_document
      @root_document = false
      yield
      @root_document = previous_root_document
      if @indent
        @io << '\n'
        array_nest.times do
          @io << @indent
        end
      end
      @io << ']'
    end

    def hash(key : String, &block)
      key(key)
      @begin_array = false
      previous_root_document = @root_document
      @root_document = false
      hash { yield }
      @root_document = previous_root_document
    end

    def hash(&block)
      @begin_hash = true
      if @root_document
        yield
      else
        hash_nest = @nest
        increment_nest
        @io << '{'
        @io << '\n' if @indent
        yield
        if @indent
          hash_nest.times do
            @io << @indent
          end
        end
        @io << '}'
        @io << '\n' if @indent
      end
      @begin_hash = false
    end

    private def increment_nest
      if (@nest += 1) > @max_nesting
        raise CON::Builder::Error.new("Nesting of #{@nest} is too deep")
      end
    end

    private def add_indent
      @nest.times do
        @io << @indent
      end
    end
  end

  # Returns the resulting `String` of writing CON to the yielded `CON::Builder`.
  #
  # ```
  # require "con"
  #
  # string = CON.build do |con|
  #   con.hash do
  #     con.field "name", "foo"
  #     con.hash "values" do
  #       con.array do
  #         con.value 1
  #         con.value 2
  #         con.value 3
  #       end
  #     end
  #   end
  # end
  # string # => %<name "foo" values[1 2 3]>
  # ```
  def self.build(indent = nil)
    String.build do |str|
      build(str, indent) do |con|
        yield con
      end
    end
  end

  # Writes CON into the given `IO`. A `CON::Builder` is yielded to the block.
  def self.build(io : IO, indent : String? = nil)
    builder = CON::Builder.new(io, indent)
    yield builder
  end
end
