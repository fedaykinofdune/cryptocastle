require 'fileutils'
require 'listen'

COFFEE_SOURCE_PATH = "#{File.dirname(__FILE__)}/source/coffeescripts/"

task default: :build

desc 'Start development server'
task :serve do
  `shotgun server.rb`
end

desc 'Compiles on file change'
task :watch do
  system 'rake build'
  puts "Watching for changes in #{COFFEE_SOURCE_PATH}"

  listener = Listen.to(COFFEE_SOURCE_PATH) do |modified, added, removed|
    puts "File changed: #{added.first}, recompiling..."
    system 'rake build'
  end
  listener.start
  sleep
end

desc 'Compile coffeescript source'
task :compile do
  output = "#{File.dirname(__FILE__)}/source/javascripts/"

  FileUtils.mkdir_p(output)
  `$(npm bin)/coffee -o #{output} -c #{COFFEE_SOURCE_PATH}/*.coffee`
end

desc 'Build coffeescript source'
task build: :compile do
  output = "#{File.dirname(__FILE__)}/public/javascripts"
  outputFile = "#{output}/game.js"

  FileUtils.mkdir_p(output)
  FileUtils.rm_f(outputFile)
  `$(npm bin)/browserify . --fast -t brfs | $(npm bin)/uglifyjs -o #{outputFile}`

  if $?.to_i == 0
    puts "Built successfully as #{outputFile}"
  end
end
