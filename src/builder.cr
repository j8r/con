module CON
  struct Builder
    getter io : IO
    @total_indent : String
    @previous_total_indent : String?
    @indent : String?
    @hash_braces = true
    @begin_hash = false
    @begin_array = false

    def initialize(@io : IO, @indent : String? = nil)
      @total_indent = @indent || ""
      @previous_total_indent = nil
      # Not needed at the start/end of a document
      @hash_braces = false
    end

    protected def initialize(@io : IO, indent : String?, @total_indent : String)
      # Increment the indentation, if any
      if @indent = indent
        @previous_total_indent = @total_indent
        @total_indent += indent
      end
    end

    def field(key : String, value)
      if @indent
        @io << @total_indent
      elsif @begin_array
        raise CON::Error.new("Can't use field inside an array")
      elsif !@begin_hash
        @io << ' '
      else
        @begin_hash = false
      end
      key.to_con_key self
      @io << ' '
      value.to_con Builder.new(@io, @indent, @total_indent)
      @io << '\n' if @indent
    end

    def value(value)
      if indent = @indent
        @total_indent = indent if @total_indent.empty?
        io << '\n' << @total_indent
      elsif @begin_hash
        raise CON::Error.new("Can't use value inside a hash")
      elsif !@begin_array
        @io << ' '
      else
        @begin_array = false
      end
      value.to_con Builder.new(@io, @indent, @total_indent)
    end

    private def key(value)
      if @previous_total_indent
        @io << '\n' << @previous_total_indent
      elsif !@indent && !@begin_hash && !@begin_array
        @io << ' '
      end
      value.to_con_key self
      @io << ' ' if @indent
    end

    def array(key : String, &block)
      key(key)
      @begin_array = true
      Builder.new(@io, @indent, @total_indent).array { yield }
    end

    def array(&block)
      io << '['
      @begin_array = true
      @begin_hash = false
      yield
      io << '\n' if @indent
      io << @previous_total_indent << ']'
    end

    def hash(key : String, &block)
      key(key)
      @begin_hash = true
      Builder.new(@io, @indent, @total_indent).hash { yield }
    end

    def hash(&block)
      @begin_hash = true
      if @hash_braces
        @io << '{'
        @io << '\n' if @indent
        yield
        @io << @previous_total_indent << '}'
      else
        yield
      end
      @begin_hash = false
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
