module Rake::Funnel::Integration::TeamCity
  class NUnitPlugin
    class << self
      ENV_VAR = 'teamcity.dotnet.nunitaddin'

      def setup(nunit_executable)
        return unless ENV.include?(ENV_VAR)
        addin = ENV[ENV_VAR].gsub(File::ALT_SEPARATOR, File::SEPARATOR)

        nunit = which(nunit_executable) || return

        binary = File.read(nunit)

        version = binary.match(/F\0i\0l\0e\0V\0e\0r\0s\0i\0o\0n\0*(.*?)\0\0\0/)
        return if version.nil?

        version = version[1].gsub(/\0/, '').split('.').take(3).join('.')

        puts "Installing TeamCity NUnit plugin for version #{version} in #{nunit}"
        destination = File.join(File.dirname(nunit), 'addins')
        FileUtils.mkdir_p(destination)
        FileUtils.cp(Dir.glob("#{addin}-#{version}.*"), destination)
      end

      private
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(File::PATH_SEPARATOR) : ['']

        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each { |ext|
            exe = cmd
            exe = "#{cmd}#{ext}" if File.extname(cmd).empty?
            test = File.join(path, exe)
            next if File.directory?(test)
            return test if File.executable?(test)
          }
        end

        nil
      end
    end
  end
end
