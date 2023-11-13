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
  desc 'Run all tests'
  Rake::TestTask.new(:all) do |t|
    t.libs << 'test'
    t.test_files = FileList['src/**/test/*_test.rb']
    t.verbose = true
  end

  desc 'Run tests for specific service'
  task :run, [:service] do |_task, args|
    service = args[:service]

    test_command = "ruby -Ilib:test #{__dir__}/src/#{service}/test/*_test.rb"

    system(test_command)
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
