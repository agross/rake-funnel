require 'erb'

Dir[File.join(File.dirname(__FILE__), 'assembly_version', '*.rb')].each do |path|
  require path
end

module Rake
  module Funnel
    module Support
      class AssemblyVersionWriter
        include InstantiateSymbol
        instantiate AssemblyVersion

        def initialize(type = :from_version_files, args = {})
          @type = create(type, args)
        end

        def write(target_path, languages = [])
          @type.each do |info|
            source = info[:source]
            version_info = info[:version_info]

            [languages].flatten.each do |language|
              target = target_path.call(language, version_info, source)

              contents = evaluate_erb(language, version_info, target)

              Rake.rake_output_message("Writing #{target}")
              File.write(target, contents)
            end
          end
        end

        private

        def evaluate_erb(language, version_info, target)
          template = template_for(language)

          render = ERB.new(template, nil, '%<>')
          render.filename = target
          render.result(get_binding(version_info))
        end

        def template_for(language)
          template = File.join(File.dirname(__FILE__), 'assembly_version', 'languages', language.to_s)
          raise "Language is not supported: #{language}" unless File.readable?(template)

          File.read(template)
        end

        def get_binding(version_info)
          binding
        end
      end
    end
  end
end
