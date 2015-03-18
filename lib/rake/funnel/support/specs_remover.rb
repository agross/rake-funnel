require 'rexml/document'

module Rake
  module Funnel
    module Support
      class SpecsRemover
        class << self
          def remove(args = {})
            remove_specs_from_projects(args)
            delete_test_files(args)
            remove_paket_references(args)
          end

          private
          def remove_specs_from_projects(args)
            projects(args).each do |project|
              xml = REXML::Document.new(File.read(project), attribute_quote: :quote)
              removed = remove_references(args, xml) + remove_specs(args, xml)

              write_xml(project, xml) if removed.flatten.any?
            end
          end

          def remove_paket_references(args)
            paket_references(args).each do |references|
              text = File.read(references)
              removed = remove_packages(text, args)

              File.write(references, removed) if removed != text
            end
          end

          def delete_test_files(args)
            Dir[*list(args[:specs])].uniq.each do |spec|
              RakeFileUtils.rm(spec)
            end
          end

          def list(args)
            ([] << args).flatten.compact
          end

          def projects(args)
            Dir[*list(args[:projects])]
          end

          def write_xml(project, xml)
            File.open(project, 'w+') do |file|
              xml.write(output: file, ie_hack: true)
            end
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

          def paket_references(args)
            Dir[*list(args[:paket_references])]
          end

          def remove_packages(text, args)
            list(args[:packages]).each do |package|
              text = text.gsub(/^#{package}.*\n?/i, '')
            end
            text
          end
        end
      end
    end
  end
end
