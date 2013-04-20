crypto = require 'crypto'

pool = require('../database').pool
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
  # @param {String} ip the uploader's IP address
  # @param {function(Object?, Reading?)} callback called when the reading is
  #    saved or an error occurs
  # @return null
  @createBatch: (batchData, ip, callback) ->
    digests = []
    readings = {}
    for rawReading in batchData.split(/(\n|\r)+/)
      json = rawReading.trim()
      continue if json.length is 0
      try
        reading = JSON.parse json
      catch jsonError  # Malformed JSON
        callback 'Invalid JSON data in reading'
        return
      digest = @dataDigest rawReading
      unless token = reading.uid
        callback 'Reading missing user ID (uid) property'
        return
      readings[digest] = { token: token, json: rawReading }
      digests.push digest

    # Eliminate duplicates.
    sql = "SELECT digest FROM readings WHERE digest IN ('" +
          digests.join("','") + "');"
    pool.query sql, (error, result) ->
      if error
        callback error
        return

      digests = null  # "Release" the digests array.
      if result.rowCount isnt 0
        for row in result.rows
          delete readings[row.digest]

      # Collect the user tokens from the recordings.
      tokenIndex = {}
      tokenList = []
      for digest, reading of readings
        token = reading.token
        unless token of tokenIndex
          tokenIndex[token] = tokenList.length
          tokenList.push token
      if tokenList.length is 0  # All the recordings have been uploaded before.
        callback null
        return

      App.validateUserTokens tokenList, (error, apps, app_uids) ->
        if error
          callback error
          return
        if apps is null
          callback 'Invalid user ID (uid) value in reading'
          return

        # Insert tokens.
        sql = ['INSERT INTO readings (id,app_id,app_uid,digest,created_at,' +
               'ip,json_data) VALUES ']
        values = []
        dollar = 0
        firstRow = true
        for digest, reading of readings
          index = tokenIndex[reading.token]
          app = apps[index]
          app_uid = app_uids[index]
          if app is null
            callback "User token points to invalid app", null
            return
          if app_uid is null
            callback "Invalid HMAC in user token", null

          if firstRow
            sql.push "(DEFAULT,#{app.id},$#{dollar + 1},'#{digest}'," +
                     "now(),'#{ip}',$#{dollar + 2})"
            firstRow = false
          else
            sql.push ",(DEFAULT,#{app.id},$#{dollar + 1},'#{digest}'," +
                     "now(),'#{ip}',$#{dollar + 2})"
          dollar += 2
          values.push app_uid
          values.push reading.json
        sql.push ';'

        pool.query sql.join(''), values, (error, result) ->
          if error
            callback error
            return
          callback null
    null

  # Computes a digest of a piece of JSON-encoded data.
  #
  # @param {String} jsonData
  @dataDigest: (jsonData) ->
    crypto.createHash('sha256').update(jsonData, 'utf8').digest('base64')

module.exports = Reading
