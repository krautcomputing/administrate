$(document).on 'turbolinks:load', ->
  $('.datetimepicker').datetimepicker locale: 'en-gb', format: 'YYYY-MM-DD HH:mm:ss'
  $('.datepicker').datetimepicker     locale: 'en-gb', format: 'YYYY-MM-DD'
