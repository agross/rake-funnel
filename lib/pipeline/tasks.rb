module Pipeline::Tasks; end

Dir["#{File.dirname(__FILE__)}/tasks/*.rb"].each do |path|
  require path
end
