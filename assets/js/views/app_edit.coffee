$ ->
  $appLookupResponse = $ '#app-lookup-response'
  $editAppResponse = $ '#edit-app-response'

  $('#app-lookup-form').on 'submit', (event) ->
    event.preventDefault()
    appId = $('#app-lookup-id').val()
    appSecret = $('#app-lookup-secret').val()
    $.ajax('/apps/' + encodeURIComponent(appId),
        type: 'GET', dataType: 'json',
        headers: { 'Authorization': "Bearer #{appSecret}" }).
        always (result, status, error) ->
          if status is 'success'
            $('#edit-app-id').val result.app.id
            $('#edit-app-secret').val result.app.secret
            $('#edit-app-name').val result.app.name
            $('#edit-app-url').val result.app.url
            $('#edit-app-email').val result.app.email
            $appLookupResponse.removeClass 'hidden'
          else
            console.error error

  $('#app-lookup-hide-button').click (event) ->
    $appLookupResponse.addClass 'hidden'


  $('#edit-app-form').on 'submit', (event) ->
    event.preventDefault()
    appId = $('#edit-app-id').val()
    appSecret = $('#edit-app-secret').val()
    data = {}
    for field in $('#edit-app-form').serializeArray()
      data[field.name] = field.value
    delete data['id']
    delete data['secret']
    $.ajax('/apps/' + encodeURIComponent(appId),
        type: 'PATCH', dataType: 'json',
        headers: { 'Authorization': "Bearer #{appSecret}" },
        data: JSON.stringify(data), contentType: 'application/json').
        always (result, status, error) ->
          if status is 'success'
            $appLookupResponse.addClass 'hidden'
            $editAppResponse.removeClass 'hidden'
          else
            console.error error

  $('#edit-app-hide-button').click (event) ->
    $editAppResponse.addClass 'hidden'
