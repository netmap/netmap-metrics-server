dbm = require 'db-migrate'
type = dbm.dataType

exports.up = (db, callback) ->
  db.createTable 'readings',
    id: { type: 'bigint', primaryKey: true, autoIncrement: true }
    app_id: { type: 'integer', nonNull: true }
    user_id: { type: 'string', length: 16, notNull: true }
    json_data: { type: 'text', length: 65536, notNull: true }
    created_at: { type: 'datetime', notNull: true }
    (error) ->
      db.addIndex 'readings', 'by_app_id', ['app_id', 'id'], (error) ->
        callback error

exports.down = (db, callback) ->
  db.dropTable 'apps', (error) ->
    callback error
