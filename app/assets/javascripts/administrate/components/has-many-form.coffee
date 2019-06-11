$(document)

  .on 'turbolinks:load', ->
    $('select:not([data-dont-enhance])', '.field-unit--has-many, .field-unit--belongs-to').selectize()

  .on 'click', '.field-unit--has-many .remove', (e) ->
    e.preventDefault()
    $(@).closest('.field-unit--nested').remove()
