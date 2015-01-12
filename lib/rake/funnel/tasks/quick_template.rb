require 'rake/clean'
require 'rake/tasklib'

module Rake::Funnel::Tasks
  class QuickTemplate < Rake::TaskLib
    attr_accessor :name, :search_pattern, :context

    def initialize(name = :template)
      @name = name

      @search_pattern = %w(**/*.template)
      @context = binding

      yield self if block_given?
      define
    end

    private
    def define
      results = templates.all_or_default.map { |t| result_filename(t) }
      CLEAN.include(*results)

      desc "Generate #{templates.all_or_default.join(', ')}"
      task name do
        templates.all_or_default.each do |template|
          target = result_filename(template)
          Rake.rake_output_message "Creating file #{target}"

          content = Rake::Funnel::Support::TemplateEngine.render(File.read(template), template, context)
          File.write(target, content)
        end
      end

      self
    end

    def templates
      Rake::Funnel::Support::Finder.new(search_pattern, self, 'No templates found.')
    end

    def result_filename(template)
      template.ext
    end
  end
end
