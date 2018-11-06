struct CON::Builder
  getter io : IO
  @indents : String
  @previous_indents : String?
  @indent_step : String?
  @hash_braces = true
  getter begin_hash = false
  @begin_array = false

  def initialize(@io : IO, @indent_step : String? = nil)
    @indents = ""
    @previous_indents = nil
    # Not needed at the start/end of a document
    @hash_braces = false
  end

  protected def initialize(@io : IO, indent_step : String?, @indents : String)
    # Increment the indentation, if any
    if @indent_step = indent_step
      @previous_indents = @indents
      @indents += indent_step
    end
  end

  def field(key : String, &block)
    if @indent_step
      @io << @indents
    elsif @begin_array
      raise CON::Error.new("Can't use field inside an array")
    elsif !@begin_hash
      @io << ' '
    else
      @begin_hash = false
    end
    key.to_con_key self
    @io << ' '
    yield.to_con Builder.new(@io, @indent_step, @indents)
    @io << '\n' if @indent_step
  end

  def value(value)
    if indent_step = @indent_step
      @indents = indent_step if @indents.empty?
      io << '\n' << @indents
    elsif @begin_hash
      raise CON::Error.new("Can't use value inside a hash")
    elsif !@begin_array
      @io << ' '
    else
      @begin_array = false
    end
    value.to_con Builder.new(@io, @indent_step, @indents)
  end

  def array(&block)
    io << '['
    @begin_array = true
    yield
    io << '\n' if @indent_step
    io << @previous_indents << ']'
  end

  def hash(&block)
    @begin_hash = true
    if @hash_braces
      @io << '{'
      @io << '\n' if @indent_step
      yield
      @io << @previous_indents << '}'
    else
      yield
    end
  end
end
