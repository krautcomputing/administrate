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

$(document).keypress (e) ->
  if !$(e.target).is('input, textarea')
    switch e.which
      when 102
        $filter = $('#filter_key')
        if $filter.length
          e.preventDefault()
          $filter.get(0).selectize.focus()
      when 115
        $search = $('#search_filter_value')
        if $search.length
          e.preventDefault()
          $search.focus()
