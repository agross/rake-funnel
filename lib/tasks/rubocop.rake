require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.formatters = %w(files html)
  t.options = %w(--out build/rubocop/rubocop.html)

  # Don't abort rake on failure.
  t.fail_on_error = false

  t.verbose = true
end
