# frozen_string_literal: true
class LinkedResourceBuilder
  class Literal
    attr_reader :value

    def initialize(value:)
      @value = value
    end

    delegate :to_s, to: :value
    alias as_json to_s
    alias without_context as_json
  end
end
