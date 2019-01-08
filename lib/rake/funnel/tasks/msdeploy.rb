# frozen_string_literal: true

require 'rake/tasklib'

module Rake
  module Funnel
    module Tasks
      class MSDeploy < Rake::TaskLib
        include Rake::Funnel::Support
        include Rake::Funnel::Support::MSDeploy

        attr_accessor :name, :msdeploy, :args, :log_file

        def initialize(*args, &task_block)
          setup_ivars(args)

          define(args, &task_block)
        end

        private

        def setup_ivars(args)
          @name = args.shift || :msdeploy

          @msdeploy = 'msdeploy'
          @args = {}
          @log_file = "#{@name}.log"
        end

        def define(args, &task_block) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          desc 'Deploy application' unless Rake.application.last_description

          task(name, *args) do |_, task_args|
            yield(*[self, task_args].slice(0, task_block.arity)) if task_block

            mapper = Mapper.new(:MSDeploy)
            cmd = [quote(msdeploy), mapper.map(@args)]
                  .flatten
                  .join(' ')

            RegistryPatch.new do
              shell(cmd, log_file: log_file, error_lines: /^(error|[\w\.]*exception)/i)
            end
          end

          self
        end

        def quote(value)
          value = value.gsub(/"/, '""') if value.is_a?(String)
          return %("#{value}") if value =~ /\s/

          value
        end
      end
    end
  end
end
