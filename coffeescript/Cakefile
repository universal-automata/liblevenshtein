require 'coffee-script/register' #-> Register the .coffee extension
wrench = require 'wrench'

fs            = require 'fs'
{print}       = require 'sys'
{spawn, exec} = require 'child_process'

build = (watch, callback) ->
  if typeof watch is 'function'
    callback = watch
    watch = false
  options = ['-c', '-o', 'build', 'src']
  options.unshift '-w' if watch

  coffee = spawn "#{__dirname}/node_modules/coffee-script/bin/coffee", options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) ->
    throw new Error("An unexpected error occurred") if status isnt 0

    countdown =
      count: 0
      increment: () -> ++ @count
      decrement: () -> @callback() if 0 is (-- @count) and @callback
      callback: callback

    countdown.increment()
    concat_files = (path, files) ->
      fs.open path, 'w', null, (error, fd) ->
        throw error if error

        fs.writeSync fd, '/**\n'
        fs.writeSync fd, '@license\n'
        fs.writeSync fd, fs.readFileSync('../LICENSE', 'utf8')
        fs.writeSync fd, '\n'
        fs.writeSync fd, '*/\n'

        for file in files
          fs.writeSync fd, fs.readFileSync(file, 'utf8')
          fs.writeSync fd, '\n'

        fs.close fd, (error) -> throw error if error
        countdown.decrement()

    countdown.increment()
    concat_files 'build/liblevenshtein.js', do ->
      lib_files = []
      for file in wrench.readdirSyncRecursive('build')
        lib_files.push("build/#{file}") if /\.js$/.test(file)
      lib_files

    countdown.increment()
    concat_files 'build/levenshtein-transducer.js', [
      'build/collection/dawg.js'
      'build/collection/max-heap.js'
      'build/levenshtein/transducer.js'
      'build/levenshtein/builder.js'
    ]

    countdown.increment()
    concat_files 'build/levenshtein-distance.js', [
      'build/levenshtein/distance.js'
    ]

    countdown.decrement()

task 'docs', 'Generate annotated source code with Docco', ->
  src_files = []
  for file in wrench.readdirSyncRecursive('src')
    path = "src/#{file}"
    src_files.push(path) if /\.coffee$/.test(path)
  docco = spawn "#{__dirname}/node_modules/docco/bin/docco", src_files
  docco.stdout.on 'data', (data) -> print data.toString()
  docco.stderr.on 'data', (data) -> print data.toString()
  docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
  build()

task 'minify', 'Builds and minifies liblevenshtein.js', ->
  build ->
    closure = spawn 'gradle', ['minify']
    closure.stdout.on 'data', (data) -> print data.toString()
    closure.stderr.on 'data', (data) -> print data.toString()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  build true

task 'test', 'Run the test suite', ->
  build ->
    {reporters} = require 'nodeunit'
    process.chdir __dirname
    reporters.default.run do ->
      test_dirs = ['test']
      for file in wrench.readdirSyncRecursive('test')
        path = "test/#{file}"
        test_dirs.push(path) if fs.lstatSync(path).isDirectory()
      test_dirs.sort()

