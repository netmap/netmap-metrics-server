$ ->
  $tokenGeneratorResponse = $ '#token-generator-response'
  $editAppResponse = $ '#edit-app-response'

  $('#token-generator-form').on 'submit', (event) ->
    event.preventDefault()
    appId = $('#token-generator-id').val()
    appSecret = $('#token-generator-secret').val()
    userId = $('#token-generator-uid').val()
    $.ajax('/apps/' + encodeURIComponent(appId) + '/uid/' +
        encodeURIComponent(userId), type: 'GET',
        headers: { 'Authorization': "Bearer #{appSecret}" }).
        always (result, status, error) ->
          if status is 'success'
            $('#user-token').text result.user_token
            $tokenGeneratorResponse.removeClass 'hidden'
          else
            console.error error

  $('#token-hide-button').click (event) ->
    $tokenGeneratorResponse.addClass 'hidden'
