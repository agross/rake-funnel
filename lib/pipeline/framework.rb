module Pipeline::Extensions; end
module Pipeline::Integration; end
module Pipeline::Support; end
module Pipeline::Tasks; end

Dir[
  "#{File.dirname(__FILE__)}/*.rb",
  "#{File.dirname(__FILE__)}/extensions/*.rb",
  "#{File.dirname(__FILE__)}/support/*.rb",
  "#{File.dirname(__FILE__)}/**/*.rb",
].each do |path|
  require path
end
