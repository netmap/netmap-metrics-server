# Controller logic for the /readings endpoints.

Reading = require '../models/reading'

module.exports = (application) ->
  application.post '/readings', (req, res) ->
    body = []
    req.on 'data', (chunk) ->
      body.push chunk
    req.on 'end', ->
      Reading.createBatch body.join(''), req.ip, (error) ->
        if error
          if typeof error is 'string'
            res.json 500, error: error
          else
            console.error error
            res.json 500, error: 'Internal database error.'

        res.json 200, status: 'OK'
