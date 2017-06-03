$(document).on 'turbolinks:load', ->
  $tableWrapper = $('.table__wrapper')
  if $tableWrapper.length
    tableWrapperTop = $tableWrapper[0].getBoundingClientRect().top
    tableWrapperHeight = $(window).height() - tableWrapperTop
    $tableWrapper.css 'height', tableWrapperHeight
    $tableWrapper.find('table').floatThead
      scrollContainer: true
      zIndex: null
