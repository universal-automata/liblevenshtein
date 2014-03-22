'use strict'

$ ($) ->
  transduce = $.noop

  $progs = $('textarea.programming-languages')
  defaults = levenshtein.programming_languages.join('\n')

  $term = $('input.query-term')
  $dist = $('select.edit-distance')
  $algo = $('select.algorithm')

  term = ''
  dist = 2
  algo = 'transposition'

  reset_transducer = () ->
    transduce = levenshtein.transducer({
      dictionary: levenshtein.programming_languages
      algorithm: algo
      sorted: true
    })

  filter = () ->
    if term = $.trim $term.val()
      candidates = $.map transduce(term, dist), (candidate) -> candidate[0]
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

