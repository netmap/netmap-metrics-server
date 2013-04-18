App = require './app'

# A measurement collected by the network sensors in a game client.
class Reading
  # @param {Object} fields initial values
  # @option fields {Number} id private ID, primary key
  # @option fields {Number} app_id private ID for the application submitting
  #     the recording
  # @option fields {String} uid application-specific ID for the user who
  #     submitted the recording
  # @option fields {String} json the recording data, encoded as JSON
  constructor: (fields) ->
    for own key, value of fields
      @[key] = value

  # Saves a piece of network sensor reading data to the database.
  #
  # @param {Object} jsonData the decoded JSON data representing the reading
  # @param {function(Object?, Reading?)} callback called when the reading is
  #    saved or an error occurs
  # @return null
  @create: (jsonData, callback) ->
    userToken = jsonData.uid
    App.validateUserToken userToken, (error, app, userId) ->
      # TODO(pwnall): check for dupes
      pool.query 'INSERT INTO apps (id,exuid,secret,name,url,email) ' +
          "VALUES (DEFAULT,#{exuid},'#{secret}',$1,$2,$3) RETURNING id;",
          [name, url, email], (error, result) ->
            return callback(error) if error
            id = result.rows[0].id
            app = new App(
                id: id, exuid: exuid, secret: secret, url: url, email: email)
            callback null, app
    null
