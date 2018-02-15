selector = '#modal'

@loadRemoteUrlInModal = (url, showLoading = false) ->
  $modalBody = $('.modal-body', selector)
  if showLoading
    $modalBody.text('Loading, please wait...')
  $modalBody.load url, ->
    $(@).find('a[data-method="post"], form').attr('data-remote', 'true')
    $(@).parents('.modal').trigger('content-loaded')

$(document)
  .on 'show.bs.modal', selector, (e) ->
    if e.relatedTarget?
      url = $(e.relatedTarget).data('url')
      loadRemoteUrlInModal url, true
  .on 'click', "#{selector} a:not([data-method]):not([data-remote]):not([href='#'])", (e) ->
    unless e.metaKey
      e.preventDefault()
      loadRemoteUrlInModal e.currentTarget.href
  .on 'ajax:success', selector, (_, data) ->
    if data.success?.length
      alert data.success
    $(@).modal('hide')
  .on 'ajax:error', selector, (_, xhr) ->
    alert xhr.responseJSON.error
