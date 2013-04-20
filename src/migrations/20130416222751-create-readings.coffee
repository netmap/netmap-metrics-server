dbm = require 'db-migrate'
type = dbm.dataType

exports.up = (db, callback) ->
  db.createTable 'readings',
    id: { type: 'bigint', primaryKey: true, autoIncrement: true }
    app_id: { type: 'int', nonNull: true }
    app_uid: { type: 'string', length: 16, notNull: true }
    digest: { type: 'string', length: 64, notNull: true }
    created_at: { type: 'datetime', notNull: true }
    ip: { type: 'string', length: 45, notNull: true }
    json_data: { type: 'text', notNull: true }
    (error) ->
      if error
        callback error
        return
      db.addIndex 'readings', 'readings_by_app', ['app_id', 'id'], (error) ->
        callback error

exports.down = (db, callback) ->
  db.dropTable 'readings', (error) ->
    callback error
