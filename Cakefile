{spawn, exec} = require 'child_process'
fs = require 'fs-extra'
log = console.log
path = require 'path'

async = require 'async'
glob = require 'glob'
remove = require 'remove'

task 'build', ->
  vendor ->
    build()

task 'clean', -> clean()

task 'vendor', -> vendor()

task 'test', ->
  vendor ->
    build ->
      test_cases = glob.sync 'test/js/**/*_test.js'
      test_cases.sort()  # Consistent test case order.
      run 'node node_modules/mocha/bin/mocha --colors --slow 200 ' +
          '--timeout 20000 --require test/js/helpers/setup.js ' +
          test_cases.join(' ')

task 'doc', ->
  run 'node_modules/.bin/codo src'

task 'dbmigrate', ->
  build ->
    dbMigrate()

build = (callback) ->
  fs.mkdirSync 'js' unless fs.existsSync 'js'
  fs.mkdirSync 'test/js' unless fs.existsSync 'test/js'

  commands = []

  source_dirs = glob.sync('src/**/').concat glob.sync('test/src/**/')
  for source_dir in source_dirs
    out_dir = source_dir.replace(/^src/, 'js').replace(/^test\/src/, 'test/js')
    commands.push "node node_modules/coffee-script/bin/coffee " +
        "--output #{out_dir} --compile --map " +
        path.join(source_dir, '*.coffee')

  async.eachSeries commands, run, ->
    callback() if callback

clean = (callback) ->
  dirs = ['js', 'test/js', 'public/css', 'public/js', 'assets/js/vendor']
  async.each dirs, ((dir, cb) ->
    fs.exists dir, (exists) ->
      if exists
        fs.remove dir, ->
          fs.mkdir dir, cb
      else
        cb()), callback

vendor = (callback) ->
  downloads = [
    ["https://cdnjs.cloudflare.com/ajax/libs/jquery/1.9.1/jquery.min.js",
     "assets/js/vendor/jquery.min.js"],
    ["https://cdnjs.cloudflare.com/ajax/libs/dropbox.js/0.9.2/dropbox.min.js",
     "assets/js/vendor/dropbox.min.js"],
    ["https://cdnjs.cloudflare.com/ajax/libs/html5shiv/3.6.2/html5shiv.js",
     "assets/js/vendor/html5shiv.js"]
  ]
  async.forEachSeries downloads, download, ->
    callback() if callback

dbMigrate = (callback) ->
  run 'node node_modules/db-migrate/bin/db-migrate --migrations-dir ' +
      'js/migrations up', callback

download = ([url, file], callback) ->
  if fs.existsSync file
    callback() if callback?
    return
  run "curl -o #{file} #{url}", callback

run = (args...) ->
  for a in args
    switch typeof a
      when 'string' then command = a
      when 'object'
        if a instanceof Array then params = a
        else options = a
      when 'function' then callback = a

  command += ' ' + params.join ' ' if params?
  cmd = spawn '/bin/sh', ['-c', command], options
  cmd.stdout.on 'data', (data) -> process.stdout.write data
  cmd.stderr.on 'data', (data) -> process.stderr.write data
  process.on 'SIGHUP', -> cmd.kill()
  cmd.on 'exit', (code) -> callback() if callback? and code is 0
