crypto = require 'crypto'

pool = require('../database').pool


# Metadata about an application (game) that uploads readings.
class App
  # @param {Object} fields initial values
  # @option fields {Number} id private ID, primary key
  # @option fields {String} exuid public application ID
  # @option fields {String} secret the app's HMAC key
  # @option fields {String} url URL of the application's HTTP backend
  # @option fields {String} email contact address for the app's authors
  constructor: (fields) ->
    for own key, value of fields
      @[key] = value

  # @return {Object} JSON-compatible object representing the app fields
  json: ->
    { id: @exuid, secret: @secret, url: @url, email: @email }

  # Creates an application.
  #
  # @param {String} url the URL of the application's HTTP backend
  # @param {String} email a contact address for the application's authors
  # @param {function(Object?, App?)} callback called when the application is
  #    created or an error occurs
  # @return null
  @create: (url, email, callback) ->
    crypto.pseudoRandomBytes 8, (error, exuidBuffer) ->
      return callback(error) if error
      exuid = exuidBuffer.readUInt32LE 0
      crypto.randomBytes 16, (error, secretBuffer) ->
        return callback(error) if error
        secret = secretBuffer.toString('base64').replace(/\+/g, '-').
                              replace(/\//g, '_').replace(/\=/g, '')
        pool.query 'INSERT INTO apps (id,exuid,secret,url,email) VALUES ' +
            "(DEFAULT,#{exuid},'#{secret}',$1,$2) RETURNING id;",
            [url, email], (error, result) ->
              throw error if error
              return callback(error) if error
              id = result.rows[0].id
              app = new App(
                  id: id, exuid: exuid, secret: secret, url: url, email: email)
              callback null, app
    null

  # Finds an application in the database.
  #
  # @param {String} exuid the application's externally-visible ID
  # @param {function(Object?, App?)} callback called when application is found
  #   or an error occurs
  @find: (exuid, callback) ->
    pool.query 'SELECT * FROM apps WHERE exuid=? LIMIT 1', [exuid],
        (error, result) ->
          return callback(error) if error
          return callback(null, null) if result.rowCount is 0

          appRow = result.rows[0]
          app = new App(
              id: appRow.id, exuid: appRow.exuid, secret: appRow.secret,
              url: appRow.url, email: appRow.email)
          callback null, app

module.exports = App
