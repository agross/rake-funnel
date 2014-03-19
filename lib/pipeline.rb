require 'rake'

module Pipeline; end

Dir["#{File.dirname(__FILE__)}/pipeline/*.rb"].each do |path|
  require path
end
