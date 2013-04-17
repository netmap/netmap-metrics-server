$ ->
  $newAppResponse = $ '#new-app-response'

  $('#new-app-form').on 'submit', (event) ->
    event.preventDefault()
    data = {}
    for field in $('#new-app-form').serializeArray()
      data[field.name] = field.value
    $.ajax('/apps',
        type: 'POST', dataType: 'json',
        data: JSON.stringify(data), contentType: 'application/json').
        always (result, status, error) ->
          if status is 'success'
            $('#new-app-id').text result.app.id
            $('#new-app-secret').text result.app.secret
            $newAppResponse.removeClass 'hidden'
          else
            console.error error

  $('#new-app-hide-button').click (event) ->
    $newAppResponse.addClass 'hidden'
    $editAppResponse.addClass 'hidden'
