require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.formatters = %w(progress html)
  t.options = %w(--out build/rubocop/rubocop.html)

  t.verbose = true
end
