# Controller logic for the /app endpoint.

App = require '../models/app'

appByBearerAuth = (req, res, next) ->
  auth = req.get 'Authorization'
  unless match = auth and /^Bearer\s+([^\s]*)$/.exec(auth)
    res.set('WWW-Authorize', "Bearer").
        json(401, { error: 'Use the application secret as a bearer token' })
    return
  bearer = match[1]

  App.find req.params.app_id, (error, app) ->
    if error
      console.error error
      res.json 500, error: 'Internal database error'
    else
      if app
        if app.secret is bearer
          req.bearerApp = app
          next()
        else
          res.json 403, erorr: 'Incorrect secret'
      else
        res.json 404, error: "No application with ID #{params.app_id}"


module.exports = (application) ->
  # Create user token.
  application.get '/apps/:app_id/uid/:user_id', appByBearerAuth, (req, res) ->
    app = req.bearerApp
    if user_token = app.userToken(req.params.user_id)
      res.json 200, user_token: user_token
    else
      res.json 400, error: 'Invalid user ID'

  # Create.
  application.post '/apps', (req, res) ->
    if application.locals.production
      req.body.id = null
      req.body.secret = null
    App.create req.body, (error, app) ->
      if error
        console.error error
        res.json 500, error: 'Internal database error'
      else
        res.location('apps/' + app.exuid).json(201, app: app.json())

  # Retrieve.
  application.get '/apps/:app_id', appByBearerAuth, (req, res) ->
    res.json 200, app: req.bearerApp.json()

  # Update.
  application.patch '/apps/:app_id', appByBearerAuth, (req, res) ->
    app = req.bearerApp
    app.update req.body, (error) ->
      if error
        console.error error
        res.json 500, error: 'Internal database error'
      else
        res.json 200, app: app.json()

  # Main page for app developers.
  application.get '/', (req, res) ->
    res.render 'index'
