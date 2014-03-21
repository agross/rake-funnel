module Pipeline::Support
  class Patch
    def initialize
      yield self if block_given?
    end

    def setup(&block)
      @setup = block
    end

    def reset(&block)
      @reset = block
    end

    def apply!
      return self if @memo
      @memo = (@setup || noop).call

      self
    end

    def revert!
      return self unless @memo
      (@reset || noop).call(@memo)
      @memo = nil

      self
    end

    private
    def noop
      Proc.new { }
    end
  end
end