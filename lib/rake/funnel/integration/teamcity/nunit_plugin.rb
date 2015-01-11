module Rake::Funnel::Integration::TeamCity
  class NUnitPlugin
    class << self
      ENV_VAR = 'teamcity.dotnet.nunitaddin'

      def setup(nunit_executable)
        addins = get_addin_dir(ENV[ENV_VAR]) || return
        nunit, version = read_version(nunit_executable) || return

        addin_files = find_teamcity_addins(addins, version) || return

        copy_addin_files(nunit, addin_files, version)
      end

      private
      def get_addin_dir(source)
        return nil unless source

        if File::ALT_SEPARATOR
          source.gsub(File::ALT_SEPARATOR, File::SEPARATOR)
        else
          source
        end
      end

      def read_version(executable)
        nunit = Rake::Funnel::Support::Which.which(executable) || return
        binary = File.read(nunit)

        version = binary.match(/F\0i\0l\0e\0V\0e\0r\0s\0i\0o\0n\0*(.*?)\0\0\0/)
        if version.nil?
          Rake.rake_output_message("Could read version from NUnit executable in #{nunit}")
          return
        end

        [
          nunit,
          version[1].gsub(/\0/, '').split('.').take(3).join('.')
        ]
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
        RakeFileUtils.cp(addin_files, destination)
      end
    end
  end
end
