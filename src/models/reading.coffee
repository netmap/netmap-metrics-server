crypto = require 'crypto'

App = require './app'

# A measurement collected by the network sensors in a game client.
class Reading
  # @param {Object} fields initial values
  # @option fields {Number} id private ID, primary key
  # @option fields {Number} app_id private ID for the application submitting
  #     the recording
  # @option fields {String} app_uid application-specific ID for the user who
  #     submitted the recording
  # @option fields {String} digest
  # @option fields {String} json the recording data, encoded as JSON
  constructor: (fields) ->
    for own key, value of fields
      @[key] = value

  # Saves a batch of network sensor readings to the database.
  #
  # @param {String} batchData the JSON data representing the readings; each
  #    reading's data should be JSON-encoded, and the readings should be
  #    separated by a single newline
  # @param {function(Object?, Reading?)} callback called when the reading is
  #    saved or an error occurs
  # @return null
  @createBatch: (batchData, callback) ->
    digests = []
    readings = {}
    for rawReading in batchData.split("\n")
      try
        reading = JSON.decode rawReading
      catch jsonError  # Malformed JSON
        callback 'Invalid JSON data in reading'
        return
      digest = @dataDigest rawReading
      readings[digest] = { token: digest.uid, json: rawReading }
      digests.push digest

    # Eliminate duplicates.
    sql = 'SELECT digest FROM readings WHERE digest in ("' +
          digests.join('","') + '");'
    pool.query sql, (error, result) ->
      if error
        callback error
        return

      digests = null  # "Release" the digests array.
      if result.rowCount isnt 0
        for row in result.rows
          delete readings[row.digest]

      # Resolve the apps in tokens.
      tokenIndex = {}
      tokenList = []
      for digest, reading of readings
        token = reading.token
        unless token of tokenSet
          tokenIndex[token] = tokenList.length
          tokenList.push token

      App.validateUserTokens tokenList, (error, apps, app_uids) ->
        if error
          callback error
          return

        # Insert tokens.
        sql = 'INSERT INTO readings (id,app_id,app_uid,digest,json_data) VALUES ';
        for digest, reading of readings
          index = tokenIndex[reading.token]
          app = apps[tokenIndex]
          app_uid = app_uids[tokenIndex]
          if app is null
            callback "User token points to invalid app", null
            return
          if app_uid is null
            callback "Invalid HMAC in user token", null

        callback null


    userToken = jsonData.uid
    App.validateUserToken userToken, (error, app, userId) ->
      # TODO(pwnall): check for dupes
      pool.query 'INSERT INTO recordings (id,app_id,app_uid,json) ' +
          "VALUES (DEFAULT,#{app.id},$1,$2,$3) RETURNING id;",
          [name, url, email], (error, result) ->
            return callback(error) if error
            id = result.rows[0].id
            app = new App(
                id: id, exuid: exuid, secret: secret, url: url, email: email)
            callback null, app
    null

  # Computes a digest of a piece of JSON-encoded data.
  #
  # @param {String} jsonData
  @dataDigest: (jsonData) ->
    crypto.createHash('sha256').update(jsonData, 'utf8').digest('base64')
