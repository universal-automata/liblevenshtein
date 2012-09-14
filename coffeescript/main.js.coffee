# Copyright (c) 2012 Dylon Edwards
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

do ->
  'use strict'

  fs = require('fs'); lazy = require('lazy')
  new lazy(fs.createReadStream('/usr/share/dict/american-english', encoding: 'utf8')).lines.map((line) ->
    line && line.toString()
  ).join (dictionary) ->
    dictionary.splice(0,1) # discard the empty string ...

    {levenshtein} = require('../javascripts/v1.1/liblevenshtein.min')

    dawg_start = new Date()
    dawg = new levenshtein.Dawg(dictionary)
    dawg_stop = new Date()

    dictionary_type = 'dawg'; sorted = true

    # Sanity check: Make sure that every word in the dictionary is indexed.
    errors = []
    for term in dictionary
      unless dawg.accepts(term)
        errors.push(term)
    if errors.length > 0
      for term in errors
        console.log "    {!} \"#{term}\" ::= failed to encode in dawg"

    #word = 'sillywilly'; n = 5
    word = 'dayf'; n = 2
    #word = 'parasaurolophus'; n = 20

    #algorithm = 'standard'
    algorithm = 'transposition'
    #algorithm = 'merge_and_split'

    transduce_start = new Date()
    transduce = levenshtein.transducer(dictionary: dawg, sorted: sorted, dictionary_type: dictionary_type, algorithm: algorithm)
    transduce_stop = new Date()

    distance_start = new Date()
    distance = levenshtein.distance(algorithm)
    distance_stop = new Date()

    distances_start = new Date()
    distance(word, term) for term in dictionary
    distances_stop = new Date()

    target_terms = {}
    target_terms[term] = true for term in dictionary when distance(word, term) <= n
    dictionary = null

    transduced_start = new Date()
    transduced = transduce(word, n)
    transduced_stop = new Date()

    console.log "Distances to Transduced Term(s):"
    i = 0; k = transduced.length; j = if 100 < k then 100 else k
    while i < j
      [term, d] = transduced[i]
      message = "    distance(\"#{word}\", \"#{term}\") = #{distance(word, term)} <=> #{d}"
      console.log(message)
      if distance(word, term) != d
        console.log '    ' + Array(message.length - 3).join('^')
      i += 1
    while i < k
      [term, d] = transduced[i]
      if distance(word, term) != d
        message = "    distance(\"#{word}\", \"#{term}\") = #{distance(word, term)} <=> #{d}"
        console.log(message)
        console.log '    ' + Array(message.length - 3).join('^')
      i += 1
    console.log "Total Transduced: #{transduced.length}"
    console.log '----------------------------------------'

    false_positives = []
    for [term] in transduced
      if term of target_terms
        delete target_terms[term]
      else
        false_positives.push(term)

    if false_positives.length > 0
      console.log 'Distances to Every False Positive:'
      false_positives.sort (a,b) -> distance(word, a[0]) - distance(word, b[0]) || a[0].localeCompare(b[0])
      for term in false_positives
        console.log "    distance(\"#{word}\", \"#{term}\") = #{distance(word, term)}"
      console.log "Total False Positives: #{false_positives.length}"
      console.log '----------------------------------------'

    false_negatives = []
    false_negatives.push(term) for term of target_terms

    if false_negatives.length > 0
      console.log 'Distances to Every False Negative:'
      false_negatives.sort (a,b) -> distance(word, a[0]) - distance(word, b[0]) || a[0].localeCompare(b[0])
      for term in false_negatives
        console.log "    distance(\"#{word}\", \"#{term}\") = #{distance(word, term)}"
      console.log "Total False Negatives: #{false_negatives.length}"
      console.log '----------------------------------------'

    console.log 'Calibrations:'
    console.log "    word=\"#{word}\", n=#{n}, algorithm=\"#{algorithm}\""
    console.log '----------------------------------------'
    console.log 'Benchmarks:'
    console.log "    Time to distance the dictionary: #{distances_stop - distances_start} ms"
    console.log "    Time to construct dawg: #{dawg_stop - dawg_start} ms"
    console.log "    Time to construct transducer: #{transduce_stop - transduce_start} ms"
    console.log "    Time to construct distance metric: #{distance_stop - distance_start} ms"
    console.log "    Time to transduce the dictionary: #{transduced_stop - transduced_start} ms"
    return
  return

