require "uuid"

# Adds CON support to `UUID` for use in a CON mapping.
#
# NOTE: `require "uuid/con"` is required to opt-in to this feature.
#
# ```
# require "con"
# require "uuid"
# require "uuid/con"
#
# class Example
#   CON.mapping id: UUID
# end
#
# example = Example.from_con(%({"id": "ba714f86-cac6-42c7-8956-bcf5105e1b81"}))
#
# uuid = UUID.new("87b3042b-9b9a-41b7-8b15-a93d3f17025e")
# uuid.to_con # => "87b3042b-9b9a-41b7-8b15-a93d3f17025e"
# ```
struct UUID
  def self.from_con(pull : CON::PullParser) : UUID
    UUID.from_con pull.read_value, pull
  end

  def self.from_con(value, pull : CON::PullParser) : UUID
    pull.type_error value, String if !value.is_a? String
    new value
  end

  def to_con(con : CON::Builder)
    to_s.to_con con
  end
end
