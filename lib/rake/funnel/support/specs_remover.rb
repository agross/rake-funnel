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
                Trace.message("Processing #{project} with references #{references} and specs #{specs}")

                removed_references, removed_specs = with_document(project) do |xml|
                  [remove_references(references, xml), remove_specs(specs, xml)]
                end

                {
                  project: project,
                  packages: resolve_package_names(removed_references),
                  specs: resolve_paths(project, removed_specs)
                }
              end
            end

            def with_document(project)
              xml = REXML::Document.new(File.read(project), attribute_quote: :quote)

              removed = yield(xml) if block_given?

              save(project, xml) if [removed].flatten.compact.any?

              removed
            end

            def remove_references(references, xml)
              deleted = references.map { |ref|
                query = "/Project//Reference[starts-with(lower-case(@Include), '#{ref.downcase}')]"
                xml.elements.delete_all(query)
              }
                .flatten
                .tap { |d| Trace.message("Removed references: #{d.inspect}") }

              deleted.map { |d|
                d.get_elements('/HintPath').map(&:text)
              }
                .flatten
                .tap { |d| Trace.message("HintPaths: #{d}") }
            end

            def remove_specs(specs, xml)
              deleted = specs.map { |glob|
                query = "/Project//Compile[matches(lower-case(@Include), '#{glob}')]"
                xml.elements.delete_all(query)
              }

              deleted
                .flatten
                .map { |d| d.attributes['Include'] }
                .tap { |d| Trace.message("Removed specs: #{d}") }
            end

            def save(project, xml)
              File.open(project, 'w+') do |file|
                xml.write(output: file, ie_hack: true)
              end
            end

            def resolve_package_names(references)
              references.map { |r| package_for(r) }.compact
            end

            def package_for(reference)
              path = normalize(reference)

              Pathname.new(path).ascend do |p|
                break p.parent.basename.to_s if p.basename.to_s == 'lib'
              end
            end

            def resolve_paths(project, files)
              files.map { |f| File.expand_path(File.join(File.dirname(project), normalize(f))) }
            end

            def normalize(path)
              path.gsub('\\', File::SEPARATOR)
            end
          end
        end

        class PaketReferences
          class << self
            def remove_packages(projects, packages)
              projects.each do |project|
                references = paket_references_for(project)
                Trace.message("Found #{references || 'no paket.references'} for #{project}}")

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
              Trace.message("Removing packages: #{packages.inspect}")
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

            PaketReferences.remove_packages(projects, list(args[:packages]) + packages)

            delete(specs)
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
