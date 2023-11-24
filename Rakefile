# frozen_string_literal: true

begin
  require "rake/testtask"

  Rake::TestTask.new do |t|
    t.libs << "test"
    t.libs << "src"
    t.test_files = FileList["test/**/*_test.rb"]
    t.warning    = false
    t.verbose    = true
  end
rescue LoadError
  task(:test) {}
end

namespace :test do
  task all: [ :shared, :gatekeeper]

  Rake::TestTask.new(:gatekeeper) do |t|
    t.libs << "test"
    t.test_files = FileList["#{__dir__}/src/gatekeeper/test/**/*_test.rb"]
    t.verbose    = true
  end

  Rake::TestTask.new(:shared) do |t|
    t.libs << "test"
    t.test_files = FileList["#{__dir__}/src/shared/test/**/*_test.rb"]
  end
end

begin
  require "rubocop/rake_task"

  RuboCop::RakeTask.new
rescue LoadError
  task(:rubocop) {}
end

begin
  task :steep do
    require "steep"
    require "steep/cli"

    Steep::CLI.new(argv: [ "check" ], stdout: $stdout, stderr: $stderr, stdin: $stdin).run
  end

  namespace :steep do
    task :stats do
      exec "bundle exec steep stats --log-level=fatal --format=table'"
    end
  end
rescue LoadError
  task(:steep) {}
end

task default: %i[test rubocop steep]
