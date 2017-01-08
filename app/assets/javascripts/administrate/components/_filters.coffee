$('select#filter_key').on 'change', ->
  $('.filter-values').hide()
                     .find('input, select')
                     .prop('disabled', true)
  $('form#new_filter input[type="submit"]').css('display', 'inline-block')
  filter = $(@).val()
  if filter?
    selectize = $("#filter-values-#{filter}").css('display', 'inline-block')
                                             .find('select')
                                             .prop('disabled', false)
                                             .get(0)
                                             .selectize
    selectize.enable()
    selectize.focus()

$(document).on 'keyup', (e) ->
  if e.which == 70 && !$(e.target).is('input, textarea')
    $('#filter_key').get(0).selectize.focus()
