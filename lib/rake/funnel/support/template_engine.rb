require 'erb'

module Rake::Funnel::Support
  class TemplateEngine
    class << self
      def render(template, filename = nil, binding = nil)
        render = ERB.new(replace_at_markers(template), nil, '%<>')
        render.filename = filename
        render.result(binding || top_level_binding)
      end

      private
      def replace_at_markers(template)
        tags = /(@\w[\w\.]+\w@)/

        (template || '').gsub(tags) do |match|
          "<%= #{match[1..-2]} %>"
        end
      end

      def top_level_binding
        TOPLEVEL_BINDING.dup
      end
    end
  end
end
