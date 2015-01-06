module Rake::Funnel::Integration::TeamCity; end

Dir["#{File.dirname(__FILE__)}/teamcity/*.rb"].each do |path|
  require path
end
