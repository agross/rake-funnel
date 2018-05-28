module Rake
  module Funnel
    module Integration
      module TeamCity
        class NUnitPlugin
          ENV_VAR = 'teamcity.dotnet.nunitaddin'.freeze

          class << self
            def setup(nunit_executable)
              addins = get_addin_dir(ENV[ENV_VAR]) || return
              nunit, version = read_version(nunit_executable) || return

              addin_files = find_teamcity_addins(addins, version) || return

              copy_addin_files(nunit, addin_files, version)
            end

            private

            def get_addin_dir(source)
              return nil unless source

              File.expand_path(source)
            end

            def read_version(executable)
              nunit = Rake::Funnel::Support::Which.which(executable) || return
              version = Rake::Funnel::Support::BinaryVersionReader.read_from(nunit)

              unless version.file_version
                $stderr.print("Could read version from NUnit executable in #{nunit}\n")
                return
              end

              [nunit, version.file_version.split('.').take(3).join('.')]
            end

            def find_teamcity_addins(addins, version)
              addin_files = Dir.glob("#{addins}-#{version}.*")

              if addin_files.none?
                $stderr.print("Could not find TeamCity NUnit addin for version #{version} in #{addins}\n")
                return
              end

              addin_files
            end

            def copy_addin_files(nunit, addin_files, version)
              $stderr.print("Installing TeamCity NUnit addin for version #{version} in #{nunit}\n")

              destination = File.join(File.dirname(nunit), 'addins')

              RakeFileUtils.mkdir_p(destination)
              RakeFileUtils.cp(addin_files, destination, preserve: true)
            end
          end
        end
      end
    end
  end
end
