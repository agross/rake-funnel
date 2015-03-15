module Rake::Funnel::Extensions; end
module Rake::Funnel::Integration; end
module Rake::Funnel::Support; end
module Rake::Funnel::Tasks; end

[
  "#{File.dirname(__FILE__)}/*.rb",
  "#{File.dirname(__FILE__)}/extensions/*.rb",
  "#{File.dirname(__FILE__)}/support/internal/*.rb",
  "#{File.dirname(__FILE__)}/support/*.rb",
  "#{File.dirname(__FILE__)}/*/*.rb",
].each do |path|
  Dir.glob(path).sort.each do |p|
    require p
  end
end
