# Controller logic for the /app endpoint.

module.exports = (application) ->
  # Create.
  application.post '/apps', (req, res) ->
    console.log req.params
    App.create req.params, (errors, app) ->
      if errors
        res.json 422, errors: errors
      else
        res.location('apps/' + app.ex_uid).
            json(201, id: app.ex_uid, secret: app_secret)

  # Retrieve.
  application.get '/apps/:app_id', (req, res) ->
    console.log req.params
    App.create req.params

  # Update.
  application.patch '/apps/:app_id', (req, res) ->
    res.json 500, errors: 'Not yet implemented'

  # Delete.
  application.delete '/apps/:app_id', (req, res) ->



  # Main page for app developers.
  application.get '/', (req, res) ->
    res.render 'index'
