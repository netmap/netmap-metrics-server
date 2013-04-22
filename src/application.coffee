# express.js application configuration.


http = require 'http'
path = require 'path'

cors = require 'cors'
express = require 'express'
glob = require 'glob'
rack = require 'asset-rack'

application = express()
appEnv = application.get 'env'
appRoot = path.dirname __dirname

# Settings.
application.enable 'trust proxy'
application.set 'port', process.env.PORT || 3000
application.set 'views', path.join(appRoot, 'views')
application.set 'view engine', 'ejs'
application.set 'view options', layout: false

# Locals in views.
application.locals.production = appEnv isnt 'development'

# Assets
assets = new rack.Rack [
  new rack.LessAsset
    url: '/css/application.css'
    filename: path.join(appRoot, 'assets', 'css', 'application.less')
    compress: appEnv is 'production'
  new rack.SnocketsAsset
    url: '/js/application.js'
    filename: path.join(appRoot, 'assets', 'js', 'application.coffee')
    compress: appEnv is 'production'
]
application.locals assets: assets

# Middlewares.
if appEnv is 'development'
  application.use express.logger()

application.use cors(
    methods: ['GET', 'PATCH', 'POST'], maxAge: 365 * 24 * 60 * 60,
    headers: ['Authorization', 'Content-Type'], credentials: false)
application.use assets
application.use express.static(path.join(appRoot, 'public'))
application.use express.json()
application.use express.urlencoded()
application.use application.router

if appEnv is 'development'
  application.use express.errorHandler()

# Controllers.
for controller in glob.sync(path.join(__dirname,  'controllers', '**.js'))
  require(controller)(application)


# All done.
module.exports = application
