guard :bundler do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

group :specs, halt_on_fail: true do
  guard :rspec,
        all_on_start: true,
        all_after_pass: true,
        notification: true,
        cmd: 'bundle exec rspec' do
    watch('.rspec')              { 'spec' }
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})    { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb') { 'spec' }
  end

  guard :rubocop do
    watch(%r{.+\.(rb|rake|gemspec)$})
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end
