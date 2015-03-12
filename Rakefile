require 'rake/funnel'

include Rake::Funnel

Dir['lib/tasks/*.rake'].sort.each { |file| load(file) }

task default: :spec
