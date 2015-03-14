require 'rake/clean'
require 'rake/tasklib'

module Rake::Funnel::Tasks
  class QuickTemplate < Rake::TaskLib
    include Rake::Funnel::Support

    attr_accessor :name, :search_pattern, :context

    def initialize(*args, &task_block)
      setup_ivars(args)

      define(args, &task_block)
    end

    private
    def setup_ivars(args)
      @name = args.shift || :template

      @search_pattern = %w(**/*.erb)
      @context = binding
    end

    def define(args, &task_block)
      desc 'Generate templates' unless Rake.application.last_description
      task(name, *args) do |_, task_args|
        task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block

        templates.all_or_default.each do |template|
          target = result_filename(template)
          Rake.rake_output_message "Creating file #{target}"

          content = TemplateEngine.render(File.read(template), template, context)
          File.write(target, content)
        end
      end

      self
    end

    def templates
      Finder.new(search_pattern, self, 'No templates found.')
    end

    def result_filename(template)
      template.ext
    end
  end
end
