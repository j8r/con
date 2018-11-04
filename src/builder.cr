struct CON::Builder
  getter io : IO
  @separator : String | Char | Nil = nil
  @add_separator : Bool = false
  @indents : String
  @previous_indents : String?
  @indent_step : String?
  @hash_braces = true

  def initialize(@io : IO, @indent_step : String? = nil)
    @indents = ""
    @previous_indents = nil
    # Not needed at the start/end of a document
    @hash_braces = false
  end

  protected def initialize(@io : IO, indent_step : String?, @indents : String, @separator = nil)
    # Increment the indentation, if any
    if @indent_step = indent_step
      @previous_indents = @indents
      @indents += indent_step
    end
  end

  def add_separator
    @io << @separator
  end

  def field(key : String, &block)
    if @indent_step
      @io << @indents
    elsif @add_separator
      @io << ' '
    end
    key.to_con_key self
    yield.to_con Builder.new(@io, @indent_step, @indents, ' ')
    @io << '\n' if @indent_step
    @add_separator = true
  end

  def array(&block)
    io << '['
    if indent_step = @indent_step
      @indents = indent_step if @indents.empty?
      yield Builder.new(@io, @indent_step, @indents, '\n' + @indents)
      io << '\n' << @previous_indents
    else
      yield Builder.new(@io, @indent_step, @indents, ' ')
    end
    io << ']'
  end

  def hash(&block)
    @io << @separator if @separator != ' '
    if @hash_braces
      @io << '{'
      @io << '\n' if @indent_step
      yield
      @io << @previous_indents << '}'
    else
      yield
    end
    @add_separator = false
  end
end
