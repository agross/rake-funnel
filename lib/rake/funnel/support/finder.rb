module Rake::Funnel::Support
  class Finder
    def initialize(search_pattern, task, message = nil)
      @search_pattern = search_pattern
      @task = task
      @message = message
    end

    def single_or_default
      first_sln
    end

    def single
      if first_sln.nil?
        raise Rake::Funnel::AmbiguousFileError.new(@message, @task.name, @search_pattern, candidates)
      end

      first_sln
    end

    def all_or_default
      candidates
    end

    def all
      if candidates.empty?
        raise Rake::Funnel::AmbiguousFileError.new(@message, @task.name, @search_pattern, candidates)
      end

      candidates
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
