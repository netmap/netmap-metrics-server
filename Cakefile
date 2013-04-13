{spawn, exec} = require 'child_process'
fs = require 'fs-extra'
log = console.log
path = require 'path'

async = require 'async'
glob = require 'glob'
remove = require 'remove'

task 'build', ->
  build()

task 'clean', ->
  clean()

task 'test', ->
  build ->
    tokens ->
      test_cases = glob.sync 'test/js/**/*_test.js'
      test_cases.sort()  # Consistent test case order.
      run 'node_modules/.bin/mocha --colors --slow 200 --timeout 20000 ' +
          "--require test/js/helpers/setup.js #{test_cases.join(' ')}"

task 'doc', ->
  run 'node_modules/.bin/codo src'

build = (callback) ->
  fs.mkdirSync 'js' unless fs.existsSync 'js'
  fs.mkdirSync 'test/js' unless fs.existsSync 'test/js'

  commands = []

  source_dirs = glob.sync('src/**/').concat glob.sync('test/src/**/')
  for source_dir in source_dirs
    out_dir = source_dir.replace(/^src/, 'js').replace(/^test\/src/, 'test/js')
    commands.push "node_modules/.bin/coffee --output #{out_dir} --compile " +
                  "--map #{path.join(source_dir, '*')}"

  async.eachSeries commands, run, ->
    callback() if callback

clean = (callback) ->
  async.each ['js', 'test/js', 'public/css', 'public/js'], ((dir, cb) ->
    fs.exists dir, (exists) ->
      if exists
        fs.remove dir, ->
          fs.mkdir dir, cb
      else
        cb()), callback

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
