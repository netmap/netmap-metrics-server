databaseUrl = process.env['DATABASE_URL'] || 'postgres://localhost/netmap'

exports.pool = require('any-db').createPool databaseUrl,
  min: 2, max: 10,  # TODO(pwnall): tweak based on env variables
  onConnect: (connection, done) ->
    done null, connection
