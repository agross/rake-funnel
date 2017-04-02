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
        msg = [] << inspect_description << inspect_search_pattern << inspect_candidates
        msg = msg.flatten.compact
        msg = [super.to_s] if msg.empty?

        msg.join("\n")
      end

      private

      def inspect_description
        [description] if description
      end

      def inspect_search_pattern
        ["Search pattern used: #{search_pattern}"] if search_pattern
      end

      def inspect_candidates
        return if (candidates || []).empty?
        ['Candidates:', candidates.map { |c| "  - #{c}" }]
      end
    end
  end
end
