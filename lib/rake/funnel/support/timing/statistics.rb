module Rake::Funnel::Support::Timing
  class Statistics
    include Enumerable

    attr_reader :started_at

    def initialize
      @stats = []
      @started_at = Time.now
    end

    def each(&block)
      @stats.each(&block)
    end

    def benchmark(task)
      t0 = Time.now
      begin
        yield if block_given?
      ensure
        t1 = Time.now
        @stats << { task: task, time: t1 - t0 }
      end
    end
  end
end
