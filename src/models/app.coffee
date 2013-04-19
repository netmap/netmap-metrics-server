crypto = require 'crypto'

pool = require('../database').pool


# Metadata about an application (game) that uploads readings.
class App
  # @param {Object} fields initial values
  # @option fields {Number} id private ID, primary key
  # @option fields {String} exuid public application ID
  # @option fields {String} secret the application's HMAC key
  # @option fields {String} name user-friendly name for the application
  # @option fields {String} url URL of the application's HTTP backend
  # @option fields {String} email contact address for the app's authors
  constructor: (fields) ->
    for own key, value of fields
      @[key] = value

  # @return {Object} JSON-compatible object representing the app fields
  json: ->
    { id: @exuid, secret: @secret, name: @name, url: @url, email: @email }

  # Changes an application's entry in the database.
  #
  # @option {Object} fields application data
  # @option fields {String} name user-friendly name for the application
  # @option fields {String} url the URL of the application's HTTP backend
  # @option fields {String} email a contact address for the app's authors
  # @param {function(Object?)} callback called when the application's database
  #    record is updated or an error occurs
  # @return null
  update: (fields, callback) ->
    name = fields.name or @name
    url = fields.url or @url
    email = fields.email or @email
    pool.query 'UPDATE apps SET name=$1,url=$2,email=$3 WHERE id=$4;',
        [name, url, email, @id], (error, result) ->
          return callback(error) if error
          callback null
    null

  # Computes a user token.
  #
  # @param {String} userId the application-specific user ID
  # @return {String?} the token for the given user, or null if the given user
  #     ID is invalid
  userToken: (userId) ->
    App.userToken @exuid, @secret, userId

  # Creates an application.
  #
  # @option {Object} fields application data
  # @option fields {String} name user-friendly name for the application
  # @option fields {String} url the URL of the application's HTTP backend
  # @option fields {String} email a contact address for the app's authors
  # @param {function(Object?, App?)} callback called when the application is
  #    created or an error occurs
  # @return null
  @create: (fields, callback) ->
    name = fields.name
    url = fields.url
    email = fields.email
    crypto.pseudoRandomBytes 8, (error, exuidBuffer) ->
      return callback(error) if error
      exuid = exuidBuffer.readUInt32LE 0
      crypto.randomBytes 16, (error, secretBuffer) ->
        return callback(error) if error
        secret = secretBuffer.toString('base64').replace(/\+/g, '-').
                              replace(/\//g, '_').replace(/\=/g, '')
        pool.query 'INSERT INTO apps (id,exuid,secret,name,url,email) ' +
            "VALUES (DEFAULT,#{exuid},'#{secret}',$1,$2,$3) RETURNING id;",
            [name, url, email], (error, result) ->
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
    pool.query 'SELECT * FROM apps WHERE exuid=$1 LIMIT 1', [exuid],
        (error, result) ->
          return callback(error) if error
          return callback(null, null) if result.rowCount is 0

          appRow = result.rows[0]
          app = new App(
              id: appRow.id, exuid: appRow.exuid, secret: appRow.secret,
              name: appRow.name, url: appRow.url, email: appRow.email)
          callback null, app

  # Computes a user token.
  #
  # @param {String} appId the application's externally-visible ID
  # @param {String} appSecret the application's HMAC key
  # @param {String} userId the application-specific user ID
  # @return {String?} the token for the given user, or null if the given user
  #     ID is invalid
  @userToken: (appId, appSecret, userId) ->
    if userId.indexOf('.') is -1
      "#{appId}.#{userId}.#{@_userTokenHmac(appId, appSecret, userId)}"
    else
      null

  # Decodes and verifies a batch of tokens.
  #
  # @param {Array<String>} userTokens tokens produced by the algorithm
  #     implemented in userToken
  # @param {function(Object?, Array?<App>, Array?<String>)} callback called
  #     with the validation results; the first parameter is non-null if an
  #     internal error occurred; for each token, a corresponding entry in the
  #     second parameter is non-null if the user token contains a valid app ID;
  #     the corresponding entry in the third parameter is non-null if the HMAC
  #     in the user token is valid
  # @return null
  @validateUserTokens: (userToken, callback) ->
    parts = userToken.split '3'
    if parts.length isnt 3
      callback null, null, null
      return
    exuid = parts[0]
    userId = parts[1]
    hmac = parts[2]
    @find exuid, (error, app) ->
      if error
        callback error
        return
      unless app
        callback null, null, null
        return
      if @_userTokenHmac(exuid, app.secret, userId) is hmac
        callback null, app, userId
      else
        callback null, app, null

  # Computes the HMAC in a user token.
  #
  # @param {String} appId the application's externally-visible ID
  # @param {String} appSecret the application's HMAC key
  # @param {String} userId the application-specific user ID
  @_userTokenHmac: (appId, appSecret, userId) ->
    crypto.createHmac('sha256', appSecret).update("#{appId}.#{userId}").
      digest('base64'). replace(/\+/g, '-').replace(/\//g, '_').
      replace(/\=/g, '')

module.exports = App
