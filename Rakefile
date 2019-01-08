# frozen_string_literal: true

require 'rake/funnel'

include Rake::Funnel # rubocop:disable Style/MixinUsage

Dir['lib/tasks/*.rake'].each { |file| load(file) }

task default: :spec
