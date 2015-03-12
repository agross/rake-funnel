module Rake::Funnel::Support::ArgumentMapper; end

Dir[File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb'), '*.rb')].each do |path|
  require path
end
