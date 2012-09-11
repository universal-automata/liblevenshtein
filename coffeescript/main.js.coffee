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

  {levenshtein} = require('../javascripts/v1.0/liblevenshtein.min')

  read_dictionary = (dictionary, path, encoding) ->
    bisect_left = (dictionary, term, lower, upper) ->
      while lower < upper
        i = (lower + upper) >> 1
        if dictionary[i] < term
          lower = i + 1
        else
          upper = i
      return lower

    term = ''; fs = require('fs')
    for c in fs.readFileSync(path, encoding)
      if c isnt '\n'
        term += c
      else
        dictionary.splice(bisect_left(dictionary, term, 0, dictionary.length), 0 ,term)
        term = ''
    if term isnt ''
      dictionary.splice(bisect_left(dictionary, term, 0, dictionary.length), 0 ,term)
    return

  dictionary = []; sorted = true
  read_dictionary(dictionary, '/usr/share/dict/cracklib-small', 'ascii')

  dawg_start = new Date()
  dawg = new levenshtein.Dawg(dictionary); dictionary_type = 'dawg'
  dawg_stop = new Date()

  # Sanity check: Make sure that every word in the dictionary is indexed.
  errors = []
  for term in dictionary
    unless dawg.accepts(term)
      errors.push(term)
  if errors.length > 0
    for term in errors
      console.log "    {!} \"#{term}\" ::= failed to encode in dawg"

  word = 'sillywilly'; n = 50

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

  transduced.sort (a,b) -> distance(word, a) - distance(word, b) || if a < b then -1 else if a > b then 1 else 0
  if transduced.length < 100
    console.log 'Distances to Every Transduced Term:'
    for term in transduced
      console.log "    distance(\"#{word}\", \"#{term}\") = #{distance(word, term)}"
  console.log "Total Transduced: #{transduced.length}"
  console.log '----------------------------------------'

  false_positives = []
  for term in transduced
    if term of target_terms
      delete target_terms[term]
    else
      false_positives.push(term)

  if false_positives.length > 0
    console.log 'Distances to Every False Positive:'
    false_positives.sort (a,b) -> distance(word, a) - distance(word, b) || if a < b then -1 else if a > b then 1 else 0
    for term in false_positives
      console.log "    distance(\"#{word}\", \"#{term}\") = #{distance(word, term)}"
    console.log "Total False Positives: #{false_positives.length}"
    console.log '----------------------------------------'

  false_negatives = []
  false_negatives.push(term) for term of target_terms

  if false_negatives.length > 0
    console.log 'Distances to Every False Negative:'
    false_negatives.sort (a,b) -> distance(word, a) - distance(word, b) || if a < b then -1 else if a > b then 1 else 0
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

