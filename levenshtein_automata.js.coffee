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
# Note that although I've licensed this code under the MIT license, I claim only
# ownership of the source code as described by the license; I do not claim
# ownership of any of the corresponding algorithms, unless of course I derived
# them myself.  Please do not attribute me to Levenshtein Automata or binary
# searchng.

levenshtein = do ->
  'use strict'

  EPSILON = 'ε'
  ANY = '∃'

  class Set
    constructor: (collection=null) ->
      @elements = {}
      @update(collection) if collection?

    update: (collection) ->
      if collection instanceof Set
        for value of collection.elements
          @elements[value] = true
      else if collection instanceof Array
        for value in collection
          @elements[value] = true
      else #if collection instanceof Object
        for value of collection
          @elements[value] = true
      this

    contains: (value) -> value of @elements

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

    toString: ->
      strbuf = []
      for value of @elements
        strbuf.push(value)
      strbuf.join(',')

  class NFA
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
      this

    is_final: (states) ->
      @final_states.has_intersection(states)

    _expand: (states) ->
      frontier = new Set(states)
      transitions = @transitions
      while frontier.length > 0
        state = frontier.pop()
        if state of transitions
          state_transitions = transitions[state]
          if EPSILON of state_transitions
            new_states = state_transitions[EPSILON].difference(states)
            frontier.update(new_states)
            states.update(new_states)
      states

    next_state: (states, input) ->
      dest_states = new Set()
      transitions = @transitions
      for state of states.elements
        if state of transitions
          state_transitions = transitions[state]
          if input of state_transitions
            dest_states.update(state_transitions[input])
          if ANY of state_transitions
            dest_states.update(state_transitions[ANY])
      @_expand(dest_states)

    get_inputs: (states) ->
      inputs = new Set()
      for state of states.elements
        inputs.update(@transitions[state]) if state of @transitions
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
      @transitions[src] ||= {}
      @transitions[src][input] = dest
      this

    set_default_transition: (src, dest) ->
      @defaults[src] = dest
      this

    add_final_state: (state) ->
      @final_states.add(state)
      this

    is_final: (state) ->
      @final_states.contains(state)

    next_state: (src, input) ->
      transitions = @transitions
      if src of transitions and input of transitions[src]
        transitions[src][input]
      else if src of @defaults
        @defaults[src]
      else
        null

    next_valid_string: (input) ->
      state = @start_state
      stack = []

      # Evaluate the DFA as far as possible
      broke = false
      for edge, i in input
        stack.push([input[0...i], state, edge])
        state = @next_state(state, edge)
        if state is null
          broke = true
          break
      unless broke
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
          if @is_final(state)
            return path
          stack.push([path, state, null])
      return null

    find_next_edge: (state, edge) ->
      if edge is null
        edge = '\0'
      else
        edge = String.fromCharCode(edge.charCodeAt(0) + 1)
      if state of @transitions
        state_transitions = @transitions[state]
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
  construct_nfa = (term, k) ->
    nfa = new NFA([0,0])
    for c, i in term
      for e in [0...k+1]
        # Correct character
        nfa.add_transition([i,e], c, [i + 1, e])
        if e < k
          # Deletion
          nfa.add_transition([i,e], ANY, [i, e+1])
          # Insertion
          nfa.add_transition([i,e], EPSILON, [i+1, e+1])
          # Substitution
          nfa.add_transition([i,e], ANY, [i+1,e+1])
    for e in [0...k+1]
      if e < k
        nfa.add_transition([term.length, e], ANY, [term.length, e+1])
      nfa.add_final_state([term.length, e])
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
  find_all_matches = (term, k, lookup) ->
    start = new Date()

    nfa_start = new Date()
    automaton = construct_nfa(term, k)
    nfa_stop = new Date()

    dfa_start = new Date()
    automaton = automaton.to_dfa()
    dfa_stop = new Date()

    match_start = new Date()
    match = automaton.next_valid_string('\0')
    matches = []
    while match isnt null
      next = lookup(match)
      break if next is null
      if match is next
        matches.push(match)
        next = next + '\0'
      match = automaton.next_valid_string(next)
    match_stop = new Date()

    stop = new Date()

    console.log "Construction of NFA := #{nfa_stop - nfa_start} milliseconds"
    console.log "Conversion from NFA to DFA := #{dfa_stop - dfa_start} milliseconds"
    console.log "Time to Find All Matches := #{match_stop - match_start} milliseconds"
    console.log "Total Time := #{stop - start} milliseconds"

    matches

  return {
    bisect_left: bisect_left
    construct_nfa: construct_nfa
    find_all_matches: find_all_matches
  }

matcher = (list) ->
  lookup = (term) ->
    lookup.probes += 1
    pos = levenshtein.bisect_left(list, term)
    if pos < list.length
      list[pos]
    else
      null
  lookup.probes = 0
  lookup

terms = '''
  id
  name
  avatar_uri
  children
  friends
  family
  pets
  cars
  houses
  boats
'''.split(/\s+/)

terms.sort()

term = 'naem'
lookup = matcher(terms)
console.log levenshtein.find_all_matches(term, 2, lookup)
console.log ['probes', lookup.probes]
