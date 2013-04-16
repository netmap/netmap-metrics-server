dbm = require 'db-migrate'
type = dbm.dataType

exports.up = (db, callback) ->
  db.createTable 'apps',
    id: { type: 'integer', primaryKey: true, autoIncrement: true }
    exuid: { type: 'bigint', nonNull: true, unique: true }
    secret: { type: 'string', length: 64, notNull: true }
    url: { type: 'string', length: 256, notNull: true }
    email: { type: 'string', length: 256, notNull: true }
    (error) ->
      callback error

exports.down = (db, callback) ->
  db.dropTable 'apps', (error) ->
    callback error
