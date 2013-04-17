$ ->
  $newAppResponse = $ '#new-app-response'
  $appLookupResponse = $ '#app-lookup-response'

  $('#new-app-button').click (event) ->
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


  $('#app-lookup-button').click (event) ->
    appId = $('#app-lookup-id').val()
    appSecret = $('#app-lookup-secret').val()
    $.ajax('/apps/' + encodeURIComponent(appId),
        type: 'GET', dataType: 'json',
        headers: { 'Authorization': "Bearer #{appSecret}" }).
        always (result, status, error) ->
          if status is 'success'
            $('#edit-app-id').text result.app.id
            $('#edit-app-secret').text result.app.secret
            $('#edit-app-name').text result.app.name
            $('#edit-app-url').text result.app.url
            $('#edit-app-email').text result.app.email
            $appLookupResponse.removeClass 'hidden'
          else
            console.error error

  $('#app-lookup-hide-button').click (event) ->
    $appLookupResponse.addClass 'hidden'
