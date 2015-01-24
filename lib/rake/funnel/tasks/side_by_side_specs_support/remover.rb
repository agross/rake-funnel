require 'rexml/document'

module Rake::Funnel::Tasks::SideBySideSpecsSupport
  class Remover
    class << self
      DEFAULTS = {
        projects: [],
        references: [],
        specs: []
      }

      def remove(args = {})
        args = DEFAULTS.merge(args)

        projects(args).each do |project|
          xml = REXML::Document.new(File.read(project), { attribute_quote: :quote })

          removed = remove_references(args, xml) + remove_specs(args, xml)

          write_xml(project, xml) if removed.flatten.any?
        end

        delete_specs(args)
      end

      private
      def write_xml(project, xml)
        File.open(project, 'w+') do |file|
          xml.write(output: file, ie_hack: true)
        end
      end

      def delete_specs(args)
        Dir[*args[:specs]].uniq.each do |spec|
          RakeFileUtils.rm(spec)
        end
      end

      def projects(args)
        Dir[*args[:projects]]
      end

      def list(args)
        ([] << args).flatten
      end

      def remove_references(args, xml)
        list(args[:references]).map do |ref|
          query = "/Project//Reference[starts-with(lower-case(@Include), '#{ref.downcase}')]"
          xml.elements.delete_all(query)
        end
      end

      def remove_specs(args, xml)
        list(args[:specs]).map do |glob|
          query = "/Project//Compile[matches(lower-case(@Include), '#{glob}')]"
          xml.elements.delete_all(query)
        end
      end
    end
  end
end
