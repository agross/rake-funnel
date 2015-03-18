require 'pathname'
require 'rexml/document'

module Rake
  module Funnel
    module Support
      class SpecsRemover
        class ProjectFiles
          class << self
            def remove_specs_and_references(projects, references, specs)
              deleted = remove(projects, references, specs)

              projects = deleted.map { |e| e[:project] }.flatten.uniq
              packages = deleted.map { |e| e[:packages] }.flatten.uniq
              specs = deleted.map { |e| e[:specs] }.flatten.uniq

              [projects, packages, specs]
            end

            private
            def remove(projects, references, specs)
              Dir[*projects].map do |project|
                xml = REXML::Document.new(File.read(project), attribute_quote: :quote)
                references = remove_references(references, xml)
                specs = remove_specs(specs, xml)

                save(project, xml) if (references + specs).any?

                {
                  project: project,
                  packages: resolve_package_names(project, references),
                  specs: resolve_paths(project, specs)
                }
              end
            end

            def remove_references(references, xml)
              deleted = references.map do |ref|
                query = "/Project//Reference[starts-with(lower-case(@Include), '#{ref.downcase}')]"
                xml.elements.delete_all(query)
              end

              deleted.flatten.map { |d|
                d.get_elements('/HintPath').map(&:text)
              }.flatten
            end

            def remove_specs(specs, xml)
              deleted = specs.map do |glob|
                query = "/Project//Compile[matches(lower-case(@Include), '#{glob}')]"
                xml.elements.delete_all(query)
              end

              deleted.flatten.map { |d| d.attributes['Include'] }
            end

            def save(project, xml)
              File.open(project, 'w+') do |file|
                xml.write(output: file, ie_hack: true)
              end
            end

            def resolve_package_names(project, references)
              references.map { |r| package_for(project, r) }.compact
            end

            def package_for(project, reference)
              path = File.expand_path(File.join(project, reference))

              Pathname.new(path).ascend do |p|
                break p.parent.basename.to_s if p.basename.to_s == 'lib'
              end
            end

            def resolve_paths(project, files)
              files.map { |f| File.expand_path(File.join(File.dirname(project), f)) }
            end
          end
        end

        class PaketReferences
          class << self
            def remove_packages(projects, packages)
              projects.each do |project|
                references = paket_references_for(project)
                next unless references

                text = File.read(references)
                removed = remove(text, packages)

                File.write(references, removed) if removed != text
              end
            end

            private
            def paket_references_for(project)
              project_specific = project + '.paket.references'
              global = File.join(File.dirname(project), 'paket.references')

              [project_specific, global].select { |f| File.exist?(f) }.first
            end

            def remove(text, packages)
              packages.each do |package|
                text = text.gsub(/^#{package}.*\n?/i, '')
              end
              text
            end
          end
        end

        class << self
          def remove(args = {})
            projects, packages, specs = ProjectFiles.remove_specs_and_references(list(args[:projects]),
                                                                                 list(args[:references]),
                                                                                 list(args[:specs]))

            delete(specs)

            PaketReferences.remove_packages(projects, list(args[:packages]) + packages)
          end

          private
          def list(args)
            ([] << args).flatten.compact
          end

          def delete(files)
            files.each do |file|
              RakeFileUtils.rm(file) if File.exist?(file)
            end
          end
        end
      end
    end
  end
end
