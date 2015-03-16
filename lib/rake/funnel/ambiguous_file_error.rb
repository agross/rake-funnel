module Rake
  module Funnel
    class AmbiguousFileError < StandardError
      attr_reader :task_name, :search_pattern, :candidates, :description

      def initialize(message, task_name, search_pattern, candidates)
        description = "Could not run task '#{task_name}'. #{message}"
        super(description)

        @description = description
        @task_name = task_name
        @search_pattern = search_pattern
        @candidates = candidates
      end

      def to_s
        msg = []
        (msg << description) if description
        (msg << "Search pattern used: #{@search_pattern}") if @search_pattern
        unless (@candidates || []).empty?
          msg << 'Candidates:'
          msg << @candidates.map { |c| "  - #{c}" }
        end

        msg = [super.to_s] if msg.empty?

        msg.join("\n")
      end
    end
  end
end
