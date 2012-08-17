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

################################################################################
# Initial porting of the Levenshtein Automata algorithm given in the following
# article, from Python to CoffeeScript:
#
#   http://blog.notdot.net/2010/07/Damn-Cool-Algorithms-Levenshtein-Automata
#

levenshtein = do ->
  'use strict'

  EPSILON = 'ε'
  ANY = '∃'

  class Set
    constructor: (collection) ->
      @elements = {}
      @update(collection) if collection

    toString: ->
      if @_string
        @_string
      else
        strbuf = []
        for value of @elements
          strbuf.push(value)
        @_string = strbuf.join(',')

    update: (object) ->
      elements = @elements
      for value of object
        elements[value] = true
      return

    has_intersection: (set) ->
      elements = set.elements
      for value of @elements
        return true if value of elements
      false

    difference: (set) ->
      difference = new Set()
      elements = set.elements
      for value of @elements
        unless value of elements
          difference.add(value)
      difference

    add: (value) ->
      @elements[value] = true

    pop: ->
      for value of @elements
        delete @elements[value]
        return value
      null

  class NFA
    constructor: (start_state) ->
      @transitions = {}
      @final_states = new Set()
      @_start_state = start_state

    start_state: ->
      set = new Set()
      set.add(@_start_state)
      @_expand(set)

    add_transition: (src, input, dest) ->
      transition = @transitions[src]
      unless transition
        transition = @transitions[src] = {}
      set = transition[input]
      unless set
        set = transition[input] = new Set()
      set.add(dest)
      return

    add_final_state: (state) ->
      @final_states.add(state)
      return

    is_final: (states) ->
      @final_states.has_intersection(states)

    _expand: (states) ->
      frontier = new Set(states)
      transitions = @transitions
      while state_transitions = transitions[frontier.pop()]
        if state_transitions
          epsilon_transition = state_transitions[EPSILON]
          if epsilon_transition
            new_states = epsilon_transition.difference(states)
            frontier.update(new_states)
            states.update(new_states)
      states

    next_state: (states, input) ->
      dest_states = new Set()
      transitions = @transitions
      for state of states.elements
        state_transitions = transitions[state]
        if state_transitions
          state_transition = state_transitions[input]
          if state_transition
            dest_states.update(state_transition.elements)
          state_transition = state_transitions[ANY]
          if state_transition
            dest_states.update(state_transition.elements)
      @_expand(dest_states)

    get_inputs: (states) ->
      inputs = new Set()
      transitions = @transitions
      for state of states.elements
        transition = transitions[state]
        if transition
          inputs.update(transition)
      inputs

    to_dfa: ->
      start_state = @start_state()
      dfa = new DFA(start_state)
      frontier = [start_state]
      visited = {}
      while frontier.length > 0
        current = frontier.pop()
        inputs = @get_inputs(current)
        for input of inputs.elements
          if input is EPSILON then continue
          new_state = @next_state(current, input)
          unless new_state of visited
            frontier.push(new_state)
            visited[new_state] = true
            if @is_final(new_state)
              dfa.add_final_state(new_state)
          if input is ANY
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
      transition = @transitions[src]
      unless transition
        transition = @transitions[src] = {}
      transition[input] = dest
      return

    set_default_transition: (src, dest) ->
      @defaults[src] = dest
      return

    add_final_state: (state) ->
      @final_states.add(state)
      return

    is_final: (state) -> state of @final_states.elements

    next_state: (src, input) ->
      transition = @transitions[src]
      if transition
        state = transition[input]
        return state if state
      state = @defaults[src]
      return state if state
      null

    next_valid_string: (input) ->
      state = @start_state
      stack = []

      # Evaluate the DFA as far as possible
      for edge, i in input
        stack.push([input[0...i], state, edge])
        break unless state = @next_state(state, edge)

      if state
        stack.push([input[0...i+1], state, null])
        if @is_final(state)
          # Input term is already valid
          return input

      # Perform a 'wall following' search for the lexicographically smallest
      # accepting state.
      while stack.length > 0
        [path, state, edge] = stack.pop()
        edge = @find_next_edge(state, edge)
        if edge
          path += edge
          state = @next_state(state, edge)
          return path if @is_final(state)
          stack.push([path, state, null])
      return null

    find_next_edge: (state, edge) ->
      if edge is null
        edge = '\0'
      else
        edge = String.fromCharCode(edge.charCodeAt(0) + 1)
      state_transitions = @transitions[state]
      if state_transitions
        if edge of state_transitions
          return edge
        labels = []
        for label of state_transitions
          labels.splice(bisect_left(labels, label), 0, label)
        index = bisect_left(labels, edge)
        if index < labels.length
          return labels[index]
      if state of @defaults
        return edge
      return null

  bisect_left = (array, edge, lo=0, hi=array.length) ->
    while lo < hi
      i = (lo + hi) >> 1
      if array[i] < edge
        lo = i + 1
      else
        hi = i
    return lo

  # term := term for the automaton of edit distances of k to construct
  # k := edit distance of automaton
  build_nfa = (term, k) ->
    pair = (i, j) -> '(' + i + ',' + j + ')'
    nfa = new NFA(pair(0,0))
    for c, i in term
      for e in [0...k+1]
        # Correct character
        nfa.add_transition(pair(i,e), c, pair(i+1, e))
        if e < k
          # Deletion
          nfa.add_transition(pair(i,e), ANY, pair(i, e+1))
          # Insertion
          nfa.add_transition(pair(i,e), EPSILON, pair(i+1, e+1))
          # Substitution
          nfa.add_transition(pair(i,e), ANY, pair(i+1,e+1))
    term_length = term.length
    for e in [0...k+1]
      if e < k
        nfa.add_transition(pair(term_length, e), ANY, pair(term_length, e+1))
      nfa.add_final_state(pair(term_length, e))
    nfa

  # Uses lookup to find all terms within levenshtein distance k of term.
  #
  # Args:
  #   term: The term to look up
  #   k: Maximum edit distance
  #   lookup: A single argument function that returns the first term in the
  #   database that is greater than or equal to the input argument.
  # Yields:
  #   Every matching term within levenshtein distance k from the database.
  find_all_matches = (automaton, lookup) ->
    matches = []; next = '\0'
    while match = automaton.next_valid_string(next)
      next = lookup(match)
      break if next is null
      if match is next
        matches.push(match)
        next = next + '\0'
    matches

  # A simple, recursive method to calculate the Levenshtein distance between
  # words v and w, using the following primitive operations: deletion,
  # insertion, and substitution.  Several other operations can be added below,
  # such as transpositions and merge-and-splits, but these suffice since they
  # are all that the automata generated by this library support (currently).
  #
  # Source: http://www.fmi.uni-sofia.bg/fmi/logic/theses/mitankin-en.pdf
  distance = (v, w) ->
    if v is '' or w is ''
      Math.max(v.length, w.length)
    else # v.length >= 1 and w.length >= 1
      a = v[0]; s = v[1..]
      b = w[0]; t = w[1..]
      Math.min(
        (if a is b then distance(s,t) else Infinity),
        1 + distance(s,w),
        1 + distance(v,t),
        1 + distance(s,t))

  sanity_check = ->
    keys = []
    for own key of Object.prototype
      keys.push(key)
    if keys.length
      throw new Error("Expected Object.prototype to have no custom properties, but found these: #{JSON.stringify(keys)}")
    return

  return {
    Set: Set
    NFA: NFA
    DFA: DFA
    bisect_left: bisect_left
    build_nfa: build_nfa
    find_all_matches: find_all_matches
    distance: distance
    sanity_check: sanity_check
  }

main = ->
  # It is always suggested to run this, to ensure that the library can function
  # correctly.  Note that it will throw an exception if it fails the check, so
  # you should place it within a try-catch block.
  levenshtein.sanity_check()

  matcher = (corpus) ->
    lookup = (term) ->
      lookup.probes += 1
      position = levenshtein.bisect_left(corpus, term)
      if position < corpus.length
        corpus[position]
      else
        null
    lookup.probes = 0
    lookup

  corpus = '''
    id
    name
    avatar
    children
    friends
    family
    pets
    cars
    houses
    boats
  '''.split(/\s+/)

  corpus.sort()

  lookup = matcher(corpus)
  term = 'test'
  k = 5 # WARNING: Don't set this too high (it increases the work exponentially)

  start = new Date()

  nfa_start = new Date()
  automaton = levenshtein.build_nfa(term, k)
  nfa_stop = new Date()

  dfa_start = new Date()
  automaton = automaton.to_dfa()
  dfa_stop = new Date()

  match_start = new Date()
  matches = levenshtein.find_all_matches(automaton, lookup)
  match_stop = new Date()

  distance_start = new Date()
  for match, i in matches
    matches[i] = [match, levenshtein.distance(term, match)]
  distance_stop = new Date()

  sort_start = new Date()
  matches.sort (v, w) ->
    [a, x] = v
    [b, y] = w
    if x < y
      -1
    else if x > y
      1
    else if a < b
      -1
    else if a > b
      1
    else
      0
  sort_stop = new Date()

  stop = new Date()

  console.log '--------------------------------------------------------------------------------'
  console.log "Corpus := #{JSON.stringify(corpus)}"
  console.log "Term := \"#{term}\""
  console.log "Maximum Edit Distance := #{k}"
  console.log "Matches := #{JSON.stringify(matches)}"
  console.log '--------------------------------------------------------------------------------'
  console.log "NFA Construction := #{nfa_stop - nfa_start} milliseconds"
  console.log "Conversion of NFA to DFA := #{dfa_stop - dfa_start} milliseconds"
  console.log "Time to Find All Matches := #{match_stop - match_start} milliseconds"
  console.log "Time to determine distances := #{distance_stop - distance_start} milliseconds"
  console.log "Time to sort results according to distance := #{sort_stop - sort_start} milliseconds"
  console.log "Total Time := #{stop - start} milliseconds"
  console.log '--------------------------------------------------------------------------------'
main()
