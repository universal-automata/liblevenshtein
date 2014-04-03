$ ($) ->
  'use strict'

  hljs.initHighlightingOnLoad()

  transducer = null

  $term = $('input.query-term')
  $dist = $('select.edit-distance')
  $algo = $('select.algorithm')

  term = ''
  dist = 2
  algo = 'transposition'

  builder = new levenshtein.Builder()
    .dictionary(levenshtein.programming_languages, true)
    .include_distance(true)
    .case_insensitive_sort(true)
    .sort_candidates(true)

  reset_transducer = () ->
    transducer = builder.algorithm(algo).transducer()

  $unfiltered_results = $('table.unfiltered-results')
  $unfiltered_results_body = $unfiltered_results.find('tbody:first')
  $filtered_results = $('table.filtered-results')
  $filtered_results_tbody = $filtered_results.find('tbody:first')

  $.each levenshtein.programming_languages,
    (index, language) ->
      $unfiltered_results_body.append $ \
        '<tr>' +
          "<td class='language'>#{language}</td>" +
        '</tr>'

  filter = () ->
    if term = $.trim $term.val()
      $unfiltered_results.hide()
      $filtered_results.hide()
      $filtered_results_tbody.empty()
      $.each transducer.transduce(term, dist),
        (index, [candidate, distance]) ->
          $filtered_results_tbody.append $ \
            '<tr>' +
              "<td class='language'>#{candidate}</td>" +
              "<td class='distance'>#{distance}</td>" +
            '</tr>'
      $filtered_results.show()
    else
      $filtered_results.hide()
      $unfiltered_results.show()
    null

  $term.keyup (event) ->
    filter()
    true

  $dist.change (event) ->
    dist = +$dist.find('option:selected').val()
    filter()
    true

  $algo.change (event) ->
    algo = $algo.find('option:selected').val()
    reset_transducer()
    filter()
    true

  $dist.val(dist) #-> 0-indexed
  $algo.find("option[value='#{algo}']").prop('selected', true)
  reset_transducer()
  filter()
  $term.focus()
  true

