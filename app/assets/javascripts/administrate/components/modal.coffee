selector = '#modal'

loadRemoteUrlToModalBody = ($modalBody, url) ->
  $modalBody.load url, ->
    $(@).find('a[data-method="post"], form').attr('data-remote', 'true')
    $(@).parents('.modal').trigger('content-loaded')

$(document)
  .on 'show.bs.modal', selector, (e) ->
    url = $(e.relatedTarget).data('url')
    $modalBody = $(@).find('.modal-body')
    $modalBody.text('Loading, please wait...')
    loadRemoteUrlToModalBody $modalBody, url
  .on 'click', "#{selector} a:not([data-method]):not([data-remote]):not([href='#'])", (e) ->
    unless e.metaKey
      e.preventDefault()
      loadRemoteUrlToModalBody $(@).parents('.modal-body'), e.currentTarget.href
  .on 'ajax:success', selector, (_, data) ->
    if data.success?.length
      alert data.success
    $(@).modal('hide')
  .on 'ajax:error', selector, (_, xhr) ->
    alert xhr.responseJSON.error
