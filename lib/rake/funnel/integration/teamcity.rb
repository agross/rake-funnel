# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/teamcity/*.rb"].each do |path|
  require path
end
