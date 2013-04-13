# Controller logic for the /readings endpoints.

module.exports = (application) ->
  application.post '/readings', (req, res) ->
    res.json 500, error: 'Not yet implemented'
