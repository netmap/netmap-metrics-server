databaseUrl = process.env['DATABASE_URL'] or
              'postgres://127.0.0.1/netmap-metrics'

exports.pool = require('any-db').createPool databaseUrl,
  min: 2, max: 10,  # TODO(pwnall): tweak based on env variables
  onConnect: (connection, done) ->
    done null, connection
