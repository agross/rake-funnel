require 'erb'

module Rake
  module Funnel
    module Support
      class TemplateEngine
        class << self
          def render(template, filename = nil, binding = nil)
            render = erb(template)
            render.filename = filename
            render.result(binding || top_level_binding)
          end

          private

          def erb(template)
            template = replace_at_markers(template)
            trim_mode = '%<>'

            return ERB.new(template, trim_mode: trim_mode) if RUBY_VERSION >= '2.6'

            ERB.new(template, nil, trim_mode)
          end

          def replace_at_markers(template)
            tags = /(@\w[\w\.]+\w@)/

            (template || '').gsub(tags) do |match|
              "<%= #{match[1...-1]} %>"
            end
          end

          def top_level_binding
            TOPLEVEL_BINDING.dup
          end
        end
      end
    end
  end
end
