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
    errors = []
    for rawReading, index in batchData.split(/(\n|\r)+/)
      json = rawReading.trim()
      continue if json.length is 0
      try
        reading = JSON.parse json
      catch jsonError  # Malformed JSON
        errors.push "Reading #{index + 1}: invalid JSON"
        continue
      digest = @_dataDigest rawReading
      unless token = reading.uid
        errors.push "Reading #{index + 1}: missing user ID (uid) property"
        continue
      readings[digest] = { token: token, json: rawReading, index: index }
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
        if errors.length is 0
          callback null
        else
          callback errors
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
          if app is false
            errors.push "Reading #{reading.index + 1}: invalid user token"
            continue
          else if app is null
            errors.push(
                "Reading #{reading.index + 1}: invalid app id in user token")
            continue
          if app_uid is null
            errors.push(
                "Reading: #{reading.index + 1}: invalid HMAC in user token")
            continue
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

        if sql.length is 1
          # All the records are invalid or duplicated.
          if errors.length is 0
            callback null
          else
            callback errors
          return

        sql.push ';'
        pool.query sql.join(''), values, (error, result) ->
          if error
            callback error
            return
          if errors.length is 0
            callback null
          else
            callback errors
    null

  # Returns a list of readings
  #
  # @param {Object} query determine which readings get returned
  # @option query {Number} limit maximum number of readings to be returned;
  #     this will be clamed to the hard limit defined by maxListSize
  # @option query {Number} startId
  # @param {function{Object?, Array?<Reading>}) callback called when the
  #    database query completes
  @list: (query, callback) ->
    startId = parseInt(query.start) or 0
    limit = Math.min parseInt(query.limit) or @maxListSize, @maxListSize

    sql = 'SELECT readings.id AS id,exuid,app_uid,created_at,ip,json_data ' +
        'FROM readings JOIN apps ON app_id=apps.id ' +
        "WHERE readings.id > #{startId} ORDER BY readings.id LIMIT #{limit};"
    pool.query sql, (error, result) ->
      if error
        callback error
        return
      apps = for appRow in result.rows
        serial: appRow.id, app_id: appRow.exuid, app_uid: appRow.app_uid,
        created_at: appRow.created_at, ip: appRow.ip,
        data: JSON.parse(appRow.json_data)
      callback null, apps

  # Maximum number of readings returned by list.
  @maxListSize: 1000

  # Computes a digest of a piece of JSON-encoded data.
  #
  # @param {String} jsonData
  @_dataDigest: (jsonData) ->
    crypto.createHash('sha256').update(jsonData, 'utf8').digest('base64')

module.exports = Reading
