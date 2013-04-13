#require('source-map-support').install()

application = require './application'

port = application.get 'port'
application.listen port, ->
  console.log "NetMap Metrics Server listening on port #{port}"
