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

# The algorithm for imitating Levenshtein automata was taken from the following
# journal article:
#
# @ARTICLE{Schulz02faststring,
#   author = {Klaus Schulz and Stoyan Mihov},
#   title = {Fast String Correction with Levenshtein-Automata},
#   journal = {INTERNATIONAL JOURNAL OF DOCUMENT ANALYSIS AND RECOGNITION},
#   year = {2002},
#   volume = {5},
#   pages = {67--85}
# }
#
# As well, this Master Thesis helped me understand its concepts:
#
#   www.fmi.uni-sofia.bg/fmi/logic/theses/mitankin-en.pdf
#
# The supervisor of the student who submitted the thesis was one of the authors
# of the journal article, above.
#
# The algorithm for constructing a DAWG (Direct Acyclic Word Graph) from the
# input dictionary of words (DAWGs are otherwise known as an MA-FSA, or Minimal
# Acyclic Finite-State Automata), was taken and modified from the following blog
# from Steve Hanov:
#
#   http://stevehanov.ca/blog/index.php?id=115
#
# The algorithm therein was taken from the following paper:
#
# @MISC{Daciuk00incrementalconstruction,
#   author = {Jan Daciuk and Bruce W. Watson and Richard E. Watson and Stoyan Mihov},
#   title = {Incremental Construction of Minimal Acyclic Finite-State Automata},
#   year = {2000}
# }
levenshtein_transducer = ({dictionary, algorithm, sorted}) ->
  STANDARD = 'standard'
  TRANSPOSITION = 'transposition'
  MERGE_AND_SPLIT = 'merge_and_split'
  
  algorithm = STANDARD unless algorithm in [STANDARD, TRANSPOSITION, MERGE_AND_SPLIT]
  sorted = false unless typeof sorted is 'boolean'

  subsumes_standard = (i,e, j,f) -> (e < f) and Math.abs(j - i) <= (f - e)
  subsumes_transposition = (i,e, j,f) -> true
  subsumes_merge_and_split = (i,e, j,f) -> true

  subsumes = switch algorithm
    when STANDARD then subsumes_standard
    when TRANSPOSITION then subsumes_transposition
    when MERGE_AND_SPLIT then subsumes_merge_and_split

  # ============================================================================
  # Taken and modified for my purposes from the following source:
  #  o http://stevehanov.ca/blog/index.php?id=115
  # ============================================================================
  #
  # This class represents a node in the directed acyclic word graph (DAWG,
  # a.k.a.  Minimal Acyclic Finite State Automaton, or MA-FSA).  It has a list
  # of edges to other nodes.  It has functions for testing whether it is
  # equivalent to another node.  Nodes are equivalent if they have identical
  # edges, and each identical edge leads to identical states.
  class DawgNode
    @next_id = 0

    constructor: ->
      @id = DawgNode.next_id; DawgNode.next_id += 1
      @final = false
      @edges = {}

    toString: ->
      unless @signature
        buffer = []
        if @final
          buffer.push('1')
        else
          buffer.push('0')
        for label, node of @edges
          buffer.push(label, node.id)
        @signature = buffer.join('_')
      @signature

  class Dawg
    constructor: (dictionary) ->
      @previous_word = ''
      @root = new DawgNode()

      # Here is a list of nodes that have not been checked for duplication.
      @unchecked_nodes = []

      # Here is a list of unique nodes that have been checked for duplication.
      @minimized_nodes = {}

      @insert(word) for word in dictionary
      @finish()

    insert: (word) ->
      # Find common prefix between word and previous word
      common_prefix = 0; previous_word = @previous_word
      upper_bound = Math.min(word.length, previous_word.length)
      while common_prefix < upper_bound
        break if word[common_prefix] isnt previous_word[common_prefix]
        common_prefix += 1

      # Check the unchecked_nodes for redundant nodes, proceeding from last one
      # down to the common prefix size.  Then truncate the list at that point.
      @minimize(common_prefix)
      unchecked_nodes = @unchecked_nodes

      # Add the suffix, starting from the correct node mid-way through the graph.
      if unchecked_nodes.length is 0
        node = @root
      else
        node = unchecked_nodes[unchecked_nodes.length - 1][2]

      i = common_prefix; n = word.length
      while i < n
        character = word[i]
        next_node = new DawgNode()
        node.edges[character] = next_node
        unchecked_nodes.push([node, character, next_node])
        node = next_node
        i += 1

      node.final = true
      @previous_word = word
      return

    finish: ->
      # minimize all unchecked_nodes
      @minimize(0)
      return

    minimize: (lower_bound) ->
      # proceed from the leaf up to a certain point
      minimized_nodes = @minimized_nodes
      unchecked_nodes = @unchecked_nodes

      while unchecked_nodes.length > lower_bound
        [parent, character, child] = unchecked_nodes.pop()
        if child of minimized_nodes
          # replace the child with the previously encountered one
          parent.edges[character] = minimized_nodes[child]
        else
          # add the state to the minimized nodes
          minimized_nodes[child] = child
      return

  k_profile = (x, term, k, i) ->
    vector = []; j = 0
    while j < k
      vector.push(x is term[i + j])
      j += 1
    vector

  k_profile_index_of = (x, W, k, i) ->
    j = 0
    while j < k
      return j if x is W[i + j]
      j += 1
    return -1

  transition_for_position = (W, n) ->
    w = W.length
    ([i,e], x) ->
      if e < n
        if i <= w - 2
          k = Math.min(n - e + 1, w - i)
          j = k_profile_index_of(x, W, k, i)
          if j == 0
            [
              [(i + 1), e]
            ]
          else if j != -1
            [
              [i, (e + 1)]
              [(i + 1), (e + 1)]
              [(i + j), (e + j - 1)]
            ]
          else
            [
              [i, (e + 1)]
              [(i + 1), (e + 1)]
            ]
        else if i == w - 1
          if x is W[i]
            [
              [(i + 1), e]
            ]
          else
            [
              [i, (e + 1)]
              [(i + 1), (e + 1)]
            ]
        else if i == w
          [
            [w, (e + 1)]
          ]
        else
          null
      else if e == n
        if i <= w - 1
          if x is W[i]
            [
              [(i + 1), n]
            ]
          else
            null
        else
          null
      else
        null

  unsubsume = (state) ->
    state.sort (a,b) -> a[1] - b[1] || a[0] - b[0]
    m = 0
    while m < state.length - 1
      [i,e] = state[m]; n = m + 1
      while n < state.length
        [j,f] = state[n]
        if subsumes(i,e, j,f)
          state.splice(n,1)
        else
          n += 1
      m += 1
    state.sort (a,b) -> a[0] - b[0] || a[1] - b[1]
    return

  transition_for_state = (W, n) ->
    stringify_state = (state) ->
      positions = []
      positions.push(i, e) for [i,e] in state
      positions.join(',')

    transition = transition_for_position(W, n)

    (state, x) ->
      state_prime = []; visited = {}

      for position in state
        next_state = transition(position, x)
        continue unless next_state
        for [i,e] in next_state
          key = (i + ',' + e)
          unless visited[key]
            visited[key] = true
            state_prime.push([i,e])

      if state_prime.length > 1
        unsubsume(state_prime)
        state_prime
      else if state_prime.length == 1
        state_prime
      else
        null

  dictionary.sort() unless sorted
  dawg = new Dawg(dictionary)

  (term, n) ->
    w = term.length; n2_1 = 2 * n + 1
    is_final = (state) ->
      for [i,e] in state
        return true if w - i <= n - e
      return false
    transition = transition_for_state(term, n)
    matches = []; stack = [['', dawg.root, [[0,0]]]]
    while stack.length > 0
      [V, q_D, M] = stack.pop()
      i = M[0][0]; w_i = w - i; k = Math.min(n2_1, w - i)
      for x, next_q_D of q_D.edges
        next_M = transition(M, x)
        if next_M
          next_V = V + x
          stack.push([next_V, next_q_D, next_M])
          if next_q_D.final and is_final(next_M)
            matches.push(next_V)
    matches

main = ->
  # A simple, recursive method to calculate the Levenshtein distance between
  # words v and w, using the following primitive operations: deletion,
  # insertion, and substitution.  Several other operations can be added below,
  # such as transpositions and merge-and-splits, but these suffice since they
  # are all that the automata generated by this library support (currently).
  #
  # Source: http://www.fmi.uni-sofia.bg/fmi/logic/theses/mitankin-en.pdf
  memoized_distance = {}
  distance = (v, w) ->
    key = v + '|' + w
    if value = memoized_distance[key]
      value
    else
      memoized_distance[key] =
        if v is ''
          w.length
        else if w is ''
          v.length
        else # v.length >= 1 and w.length >= 1
          a = v[0]; s = v[1..]
          b = w[0]; t = w[1..]
          while a is b and s.length > 0 and t.length > 0
            a = s[0]; v = s; s = s[1..]
            b = t[0]; w = t; t = t[1..]
          if a is b # s.length = 0 = t.length
            if s.length is 0
              t.length
            else
              s.length
          else if (p = distance(s,w)) is 0
            1
          else if (q = distance(v,t)) is 0
            1
          else if (r = distance(s,t)) is 0
            1
          else
            1 + Math.min(p, q, r)

  dictionary = [
    'cat'
    'dog'
    'horse'
    'man'
    'ant'
    'insect'
    'snake'
    'lizard'
    'salamander'
  ]

  word = 'slither'; n = 6
  console.log "distance(#{word}, #{term}) = #{distance(word, term)}" for term in dictionary
  console.log '----------------------------------------'

  transduce_start = new Date()
  transduce = levenshtein_transducer(dictionary: dictionary)
  transduce_stop = new Date()

  transduced_start = new Date()
  transduced = transduce(word, n)
  transduced_stop = new Date()

  transduced.sort (a,b) -> distance(word, a) - distance(word, b)
  for term in transduced
    console.log "distance(#{word}, #{term}) = #{distance(word, term)}"
  console.log '----------------------------------------'
  console.log "n = #{n}"
  console.log '----------------------------------------'
  console.log "Time to construct transducer: #{transduce_stop - transduce_start} ms"
  console.log "Time to transuce the dictionary: #{transduced_stop - transduced_start} ms"
main()
