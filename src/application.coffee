# express.js application configuration.


http = require 'http'
path = require 'path'

assets_middleware = require 'connect-assets'
cors = require 'cors'
express = require 'express'
glob = require 'glob'

# Settings.
application = express()
application.enable 'trust proxy'
application.set 'port', process.env.PORT || 3000
application.set 'views', path.join(path.dirname(__dirname), 'views')
application.set 'view engine', 'ejs'

# Middlewares.
application.use assets_middleware(
    env: application.get('env')
    build: application.get('env') isnt 'development'
    buildDir: path.join(path.dirname(__dirname), 'public')
    src: path.join(path.dirname(__dirname), 'assets'))
application.use express.static(path.join(path.dirname(__dirname), 'public'))
application.use express.bodyParser()

if application.get('env') is 'development'
  application.use express.errorHandler()

# Controllers.
for controller in glob.sync(path.join(__dirname,  'controllers', '**.js'))
  require(controller)(application)

# Boot.
http.createServer(application).listen application.get('port'), ->
  console.log 'NetMap Metrics Server listening on port ' +
              application.get('port')
