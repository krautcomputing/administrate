modalSelector = '#modal'

@loadRemoteUrlInModal = (urlOrIndex, showLoading = false) ->
  urls = $(modalSelector).data('urls') || []
  if Number.isInteger(urlOrIndex)
    urlIndex = urlOrIndex
  else
    urlIndex = urls.length
    urls.push urlOrIndex
    $(modalSelector).data 'urls', urls
  $('.back',    modalSelector).toggle urlIndex > 0
  $('.forward', modalSelector).toggle urlIndex < urls.length - 1
  $(modalSelector).data 'urlIndex', urlIndex

  $modalBody = $('.modal-body', modalSelector)
  if showLoading
    $modalBody.text('Loading, please wait...')
  $modalBody.load url, ->
    $(@).find('a[data-method="post"], form').attr('data-remote', 'true')
    $(@).parents('.modal').trigger('content-loaded')

$(document)
  .on 'show.bs.modal', modalSelector, (e) ->
    if e.relatedTarget?
      url = $(e.relatedTarget).data('url')
      loadRemoteUrlInModal url, true
  .on 'hide.bs.modal', modalSelector, ->
    $(modalSelector).data 'urls', []
  .on 'click', "#{modalSelector} a:not([data-method]):not([data-remote]):not([href='#']):not([href^='slack:'])", (e) ->
    unless e.metaKey
      e.preventDefault()
      loadRemoteUrlInModal e.currentTarget.href
  .on 'ajax:success', modalSelector, (_, data) ->
    if data.success?.length
      alert data.success
    $(@).modal('hide')
  .on 'ajax:error', modalSelector, (_, xhr) ->
    alert xhr.responseJSON.error
  .on 'click', "#{modalSelector} .modal-nav .reload", (e) ->
    e.preventDefault()
    loadRemoteUrlInModal $(modalSelector).data('urlIndex')
  .on 'click', "#{modalSelector} .modal-nav .back", (e) ->
    e.preventDefault()
    loadRemoteUrlInModal $(modalSelector).data('urlIndex') - 1
  .on 'click', "#{modalSelector} .modal-nav .forward", (e) ->
    e.preventDefault()
    loadRemoteUrlInModal $(modalSelector).data('urlIndex') + 1
