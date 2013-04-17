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
        if app.secret is req.bearer
          req.bearerApp = app
          next()
        else
          res.json 403, erorr: 'Incorrect secret'
      else
        res.json 404, error: "No application has ID #{params.id}"


module.exports = (application) ->
  # Create.
  application.post '/apps', (req, res) ->
    App.create url: req.body.url, email: req.body.email, (error, app) ->
      if error
        res.json 500, error: error
      else
        res.location('apps/' + app.exuid).json(201, app: app.json())

  # Retrieve.
  application.get '/apps/:app_id', appByBearerAuth, (req, res) ->
    res.json 200, app: req.bearerApp.json()

  # Update.
  application.patch '/apps/:app_id', appByBearerAuth, (req, res) ->
    req.bearerApp.update url: req.body.url, email: req.body.email, (error) ->


  # Main page for app developers.
  application.get '/', (req, res) ->
    res.render 'index'
