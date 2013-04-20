$ ->
  $readingUploadResponse = $ '#reading-upload-response'

  $('#reading-upload-form').on 'submit', (event) ->
    event.preventDefault()
    jsonData = $('#reading-upload-json').val()
    $.ajax('/readings',
        type: 'POST', dataType: 'json',
        data: jsonData, contentType: 'application/x-multi-json').
        always (result, status, error) ->
          if status is 'success'
            $readingUploadResponse.removeClass 'hidden'
          else
            console.error error

  $('#reading-upload-hide-button').click (event) ->
    $readingUploadResponse.addClass 'hidden'
