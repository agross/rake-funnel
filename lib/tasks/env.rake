# frozen_string_literal: true

namespace :env do
  Tasks::Environments.new do |t|
    t.default_env = :dev
  end
end
