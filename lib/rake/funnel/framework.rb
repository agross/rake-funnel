module Rake::Funnel::Extensions; end
module Rake::Funnel::Integration; end
module Rake::Funnel::Support; end
module Rake::Funnel::Tasks; end

Dir[
  "#{File.dirname(__FILE__)}/*.rb",
  "#{File.dirname(__FILE__)}/extensions/*.rb",
  "#{File.dirname(__FILE__)}/support/*.rb",
  "#{File.dirname(__FILE__)}/*/*.rb",
].each do |path|
  require path
end
