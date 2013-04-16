$ ->
  $newAppForm = $ '#new-app-form'
  $newAppResponse = $ '#new-app-response'

  $('#new-app-button').click (event) ->
    data = {}
    for field in $newAppForm.serializeArray()
      data[field.name] = field.value
    $.ajax('/apps',
        type: 'POST', dataType: 'json',
        data: JSON.stringify(data), contentType: 'application/json').
        always (data, status, error) ->
          if status is 'success'
            $('#new-app-id').text data.id
            $('#new-app-secret').text data.secret
          else
            console.error error

