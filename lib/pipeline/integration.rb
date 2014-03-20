module Pipeline::Integration; end

Dir["#{File.dirname(__FILE__)}/integration/*.rb"].each do |path|
  require path
end
