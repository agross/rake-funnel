Dir["#{File.dirname(__FILE__)}/case/*.rb"].each do |path|
  require path
end
