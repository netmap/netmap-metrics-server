# Controller logic for the /app endpoint.

App = require '../models/app'

module.exports = (application) ->
  # Create.
  application.post '/apps', (req, res) ->
    console.log req.params
    App.create req.params.url, req.params.email, (error, app) ->
      if error
        res.json 500, error: error
      else
        res.location('apps/' + app.exuid).json(201, app: app.json())

  # Retrieve.
  application.get '/apps/:app_id', (req, res) ->
    App.find req.params.id, (error, app) ->
      if error
        res.json 500, error: error
      else
        if app and app.secret is req.params.secret
          res.json 200, app: app.json()
        else
          res.json 404, error: "No application has ID #{params.id}"

  # Update.
  application.patch '/apps/:app_id', (req, res) ->
    res.json 500, error: 'Not yet implemented'

  # Delete.
  application.delete '/apps/:app_id', (req, res) ->
    res.json 500, error: 'Not yet implemented'

  # Main page for app developers.
  application.get '/', (req, res) ->
    res.render 'index'
