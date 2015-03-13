module Rake::Funnel::Integration::TeamCity
  class NUnitPlugin
    ENV_VAR = 'teamcity.dotnet.nunitaddin'

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
        version = BinaryVersionReader.read_from(nunit)

        unless version.file_version
          Rake.rake_output_message("Could read version from NUnit executable in #{nunit}")
          return
        end

        [nunit, version.file_version.split('.').take(3).join('.')]
      end

      def find_teamcity_addins(addins, version)
        addin_files = Dir.glob("#{addins}-#{version}.*")

        if addin_files.none?
          Rake.rake_output_message("Could not find TeamCity NUnit addin for version #{version} in #{addins}")
          return
        end

        addin_files
      end

      def copy_addin_files(nunit, addin_files, version)
        Rake.rake_output_message("Installing TeamCity NUnit addin for version #{version} in #{nunit}")

        destination = File.join(File.dirname(nunit), 'addins')

        RakeFileUtils.mkdir_p(destination)
        RakeFileUtils.cp(addin_files, destination, { preserve: true })
      end
    end
  end
end
