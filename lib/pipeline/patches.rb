module Pipeline::Patches; end

Dir["#{File.dirname(__FILE__)}/patches/*.rb"].each do |path|
  require path
end
