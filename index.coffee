'use strict'

$ ($) ->
  transducer = null

  $progs = $('textarea.programming-languages')
  defaults = levenshtein.programming_languages.join('\n')

  $term = $('input.query-term')
  $dist = $('select.edit-distance')
  $algo = $('select.algorithm')

  term = ''
  dist = 2
  algo = 'transposition'

  builder = new levenshtein.Builder()
    .dictionary(levenshtein.programming_languages, true)
    .maximum_candidates(10)
    .include_distance(false)
    .case_insensitive_sort(true)
    .sort_candidates(true)

  reset_transducer = () ->
    transducer = builder.algorithm(algo).transducer()

  filter = () ->
    if term = $.trim $term.val()
      candidates = transducer.transduce(term, dist)
      $progs.val candidates.join('\n')
    else
      $progs.val(defaults)
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

