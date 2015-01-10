module Rake::Funnel::Tasks::MSBuildSupport
  class Solution
    def initialize(search_pattern, task)
      @search_pattern = search_pattern
      @task = task
    end

    def find_or_nil
      first_sln
    end

    def find
      if first_sln.nil?
        raise Rake::Funnel::AmbiguousFileError.new('No projects or more than one project found.', @task.name, @search_pattern, candidates)
      end

      first_sln
    end

    private
    def first_sln
      return candidates.first if candidates.one?

      nil
    end

    def candidates
      Dir.glob(@search_pattern).select { |f| File.file?(f) }
    end
  end
end
