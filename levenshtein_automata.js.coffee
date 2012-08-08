# Copyright (c) 2012 Dylon Edwards
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
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

################################################################################
# Initial porting of the Levenshtein Automata algorithm given in the following
# article, from Python to CoffeeScript:
#
#   http://blog.notdot.net/2010/07/Damn-Cool-Algorithms-Levenshtein-Automata
#
# Note that although I've licensed this code under the MIT license, I claim only
# ownership of the source code as described by the license; I do not claim
# ownership of any of the corresponding algorithms, unless of course I derived
# them myself.  Please do not attribute me to Levenshtein Automata or binary
# searchng.

levenshtein = {}
do (levenshtein) ->
  'use strict'

  log = (params...) -> console.log(params)

  class Set extends Array
    constructor: (collection=null) ->
      @_elements = {}
      @update(collection) if collection?

    toString: ->
      strbuf = []
      for i in [0...@length]
        strbuf.push(JSON.stringify(@[i]))
      'Set([' + strbuf.join(', ') + '])'

    update: (collection) ->
      if collection instanceof Array
        for value in collection
          @add(value)
      else if collection instanceof Object
        for own value of collection
          @add(value)
      else
        throw new Error("Unsupported collection type: \"#{collection}\":\"#{typeof collection}\"")
      this

    cardinality: (value) ->
      @_elements[value] || 0

    contains: (value) ->
      value of @_elements

    intersection: (set) ->
      intersection = new Set()
      for own value of @_elements
        if value of set._elements
          intersection.add(value)
      intersection

    difference: (set) ->
      difference = new Set()
      for own value of @_elements
        if value not of set._elements
          difference.add(value)
      difference

    union: (set) ->
      union = new Set()
      for own value of @_elements
        union.add(value)
      for own value of set._elements
        union.add(value)
      union

    add: (value) ->
      unless value of @_elements
        @push(value.toString())
        @_elements[value] = 0
      @_elements[value] += 1

    remove: (value) ->
      if value of @_elements
        i = 0
        j = @length - 1
        while i <= j
          if @[i] is value
            @splice(i, 1)
            break
          if @[j] is value
            @splice(j, 1)
            break
          i += 1
          j -= 1
        delete @_elements[value]
        true
      else
        false

    pop: ->
      if @length
        value = super()
        delete @_elements[value]
        value
      else
        null

  class NFA
    @EPSILON = 'ε'
    @ANY = '∃'

    constructor: (start_state) ->
      @transitions = {}
      @final_states = new Set()
      @_start_state = start_state

    start_state: ->
      @_expand(new Set([@_start_state]))

    add_transition: (src, input, dest) ->
      @transitions[src] ||= {}
      @transitions[src][input] ||= new Set()
      @transitions[src][input].add(dest)
      this

    add_final_state: (state) ->
      @final_states.add(state)

    is_final: (states) ->
      @final_states.intersection(states)

    _expand: (states) ->
      frontier = new Set(states)
      while frontier.length > 0
        state = frontier.pop()
        @transitions[state] ||= {}
        @transitions[state][NFA.EPSILON] ||= new Set()
        new_states = @transitions[state][NFA.EPSILON].difference(states)
        frontier.update(new_states)
        states.update(new_states)
      states

    next_state: (states, input) ->
      dest_states = new Set()
      for state in states
        state_transitions = @transitions[state] || {}
        dest_states.update(state_transitions[input] || [])
        dest_states.update(state_transitions[NFA.ANY] || [])
      @_expand(dest_states)

    get_inputs: (states) ->
      inputs = new Set()
      for state in states
        inputs.update(@transitions[state]) if state of @transitions
      inputs

    to_dfa: ->
      dfa = new DFA(@start_state())
      frontier = [@start_state()]
      seen = new Set()
      while frontier.length > 0
        current = frontier.pop()
        inputs = @get_inputs(current)
        for input in inputs
          if input is NFA.EPSILON then continue
          new_state = @next_state(current, input)
          unless seen.contains(new_state)
            frontier.push(new_state)
            seen.add(new_state)
            if @is_final(new_state).length > 0
              dfa.add_final_state(new_state)
          if input is NFA.ANY
            dfa.set_default_transition(current, new_state)
          else
            dfa.add_transition(current, input, new_state)
      dfa

  class DFA

    constructor: (start_state) ->
      @start_state = start_state
      @transitions = {}
      @defaults = {}
      @final_states = new Set()

    add_transition: (src, input, dest) ->
      @transitions[src] ||= {}
      @transitions[src][input] = dest

    set_default_transition: (src, dest) ->
      @defaults[src] = dest

    add_final_state: (state) ->
      @final_states.add(state)

    is_final: (state) ->
      @final_states.contains(state)

    next_state: (src, input) ->
      state_transitions = @transitions[src] || {}
      state_transitions[input] || @defaults[src] || null

    next_valid_string: (input) ->
      state = @start_state
      stack = []

      # Evaluate the DFA as far as possible
      broke = false
      for x, i in input
        stack.push([input[0...i], state, x])
        state = @next_state(state, x)
        if state is null
          broke = true
          break
      unless broke
        stack.push([input[0...i+1], state, null])

      if @is_final(state)
        # Input word is already valid
        return input

      # Perform a 'wall following' search for the lexicographically smallest
      # accepting state.
      while stack.length > 0
        [path, state, x] = stack.pop()
        x = @find_next_edge(state, x)
        if x
          path += x
          state = @next_state(state, x)
          if @is_final(state)
            return path
          stack.push([path, state, null])
      return null

    find_next_edge: (s, x) ->
      if x is null
        x = '\0'
      else
        x = String.fromCharCode(x.charCodeAt(0) + 1)
      state_transitions = @transitions[s] || {}
      if x of state_transitions or s of @defaults
        return x
      labels = (key for own key of state_transitions)
      labels.sort()
      pos = bisect_left(labels, x)
      if pos < labels.length
        return labels[pos]
      return null

  levenshtein.bisect_left = bisect_left = (a, x, lo=0, hi=a.length) ->
    while lo < hi
      i = (lo + hi) >> 1
      if a[i] < x
        lo = i + 1
      else
        hi = i
    return lo

  # term := term for the automaton of edit distances of k to construct
  # k := edit distance of automaton
  levenshtein.automata = automata = (term, k) ->
    nfa = new NFA([0,0])
    for c, i in term
      for e in [0...k+1]
        # Correct character
        nfa.add_transition([i,e], c, [i + 1, e])
        if e < k
          # Deletion
          nfa.add_transition([i,e], NFA.ANY, [i, e+1])
          # Insertion
          nfa.add_transition([i,e], NFA.EPSILON, [i+1, e+1])
          # Substitution
          nfa.add_transition([i,e], NFA.ANY, [i+1,e+1])
    for e in [0...k+1]
      if e < k
        nfa.add_transition([term.length, e], NFA.ANY, [term.length, e+1])
      nfa.add_final_state([term.length, e])
    nfa

  # Uses lookup_func to find all words within levenshtein distance k of word.
  #
  # Args:
  #   word: The word to look up
  #   k: Maximum edit distance
  #   lookup_func: A single argument function that returns the first word in the
  #   database that is greater than or equal to the input argument.
  # Yields:
  #   Every matching word within levenshtein distance k from the database.
  levenshtein.find_all_matches = find_all_matches = (word, k, lookup_func) ->
    lev = automata(word, k).to_dfa()
    match = lev.next_valid_string('\0')
    matches = []
    while match isnt null
      next = lookup_func(match)
      break if next is null
      if match is next
        matches.push(match)
        next = next + '\0'
      match = lev.next_valid_string(next)
    matches

matcher = (l) ->
  m = (w) ->
    m.probes += 1
    pos = levenshtein.bisect_left(l, w)
    if pos < l.length
      l[pos]
    else
      null
  m.probes = 0
  m

words = ['cat', 'dog', 'horse', 'human', 'product_name']
words.sort()
term = 'product'
m = matcher(words)
log levenshtein.find_all_matches(term, 5, m)
log 'm.probes', m.probes
