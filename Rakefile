require 'fileutils'

JAVASCRIPTS_DIR = './public/javascripts'

task default: :build

def compile(command)
  outputFile = "#{JAVASCRIPTS_DIR}/game.js"

  FileUtils.mkdir_p(JAVASCRIPTS_DIR)
  FileUtils.rm_f(outputFile)

  case ENV['ENV']
  when 'production'
    `#{command} -t coffeeify -t brfs --extension=".coffee" | $(npm bin)/uglifyjs -o #{outputFile}`
  else
    `#{command} -t coffeeify -t brfs -d -x three -x tween -o #{outputFile} --fast --extension=".coffee"`
  end
end

desc 'Start development server'
task :serve do
  exec("env NODE_PATH='./vendor' $(npm bin)/nodemon server.coffee")
end

desc 'Builds the library bundle used in development mode.'
task :bundle do
  `$(npm bin)/browserify -r ./vendor/three.js:three -r tween > #{JAVASCRIPTS_DIR}/bundle.js`
end

desc 'Compiles on file change'
task watch: :bundle do
  compile('$(npm bin)/watchify . -v')
end

desc 'Build coffeescript source'
task build: :bundle do
  compile('$(npm bin)/browserify .')
end
