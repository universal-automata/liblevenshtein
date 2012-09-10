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

  STANDARD = 'standard'
  TRANSPOSITION = 'transposition'
  MERGE_AND_SPLIT = 'merge_and_split'
    
  # The algorithm for imitating Levenshtein automata was taken from the
  # following journal article:
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
  # The supervisor of the student who submitted the thesis was one of the
  # authors of the journal article, above.
  #
  # The algorithm for constructing a DAWG (Direct Acyclic Word Graph) from the
  # input dictionary of words (DAWGs are otherwise known as an MA-FSA, or
  # Minimal Acyclic Finite-State Automata), was taken and modified from the
  # following blog from Steve Hanov:
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
  transducer = ({dictionary, algorithm, sorted}) ->
    algorithm = STANDARD unless algorithm in [STANDARD, TRANSPOSITION, MERGE_AND_SPLIT]
    sorted = false unless typeof sorted is 'boolean'

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

      bisect_left: (edges, edge, lower, upper) ->
        while lower < upper
          i = (lower + upper) >> 1
          if edges[i] < edge
            lower = i + 1
          else
            upper = i
        return lower

      toString: ->
        edges = []
        for label, node of @edges # insertion sort
          edge = label + node.id.toString()
          edges.splice(@bisect_left(edges, edge, 0, edges.length), 0, edge)
        (if @final then '1' else '0') + edges.join()

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
        while common_prefix < upper_bound and word[common_prefix] is previous_word[common_prefix]
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
          child_key = child.toString()
          if child_key of minimized_nodes
            # replace the child with the previously encountered one
            parent.edges[character] = minimized_nodes[child_key]
          else
            # add the state to the minimized nodes
            minimized_nodes[child_key] = child
        return

      lookup: (word) ->
        node = @root
        for edge in word
          node = node.edges[edge]
          return false unless node
        node.final

    index_of = (vector, k, i) ->
      j = 0
      while j < k
        return j if vector[i + j]
        j += 1
      return -1

    transition_for_position = switch algorithm
      when STANDARD then (n) ->
        ([i,e], vector, offset) ->
          i -= offset; w = vector.length
          if e < n
            if i <= w - 2
              k = Math.min(n - e + 1, w - i)
              j = index_of(vector, k, i)
              if j == 0
                [
                  [(i + 1), e]
                ]
              else if j > 0
                [
                  [i, (e + 1)]
                  [(i + 1), (e + 1)]
                  [(i + j + 1), (e + j)]
                ]
              else
                [
                  [i, (e + 1)]
                  [(i + 1), (e + 1)]
                ]
            else if i == w - 1
              if vector[i]
                [
                  [(i + 1), e]
                ]
              else
                [
                  [i, (e + 1)]
                  [(i + 1), (e + 1)]
                ]
            else #i == w
              [
                [w, (e + 1)]
              ]
          else if e == n
            if i <= w - 1
              if vector[i]
                [
                  [(i + 1), n]
                ]
              else
                null
            else
              null
          else
            null

      when TRANSPOSITION then (n) ->
        ([i,e,t], vector, offset) ->
          i -= offset; w = vector.length
          if e == 0 < n
            if i <= w - 2
              k = Math.min(n - e + 1, w - i)
              j = index_of(vector, k, i)
              if j == 0
                [
                  [(i + 1), 0]
                ]
              else if j == 1
                [
                  [i, 1]
                  [i, 1, true] # t-position
                  [(i + 1), 1]
                  [(i + j + 1), j]
                ]
              else if j > 1
                [
                  [i, 1]
                  [(i + 1), 1]
                  [(i + j + 1), j]
                ]
              else
                [
                  [i, 1]
                  [(i + 1), 1]
                ]
            else if i == w - 1
              if vector[i]
                [
                  [(i + 1), 0]
                ]
              else
                [
                  [i, 1]
                  [(i + 1), 1]
                ]
            else # i == w
              [
                [w, 1]
              ]
          else if 1 <= e < n
            if i <= w - 2
              if t isnt true # [i,e] is not a t-position
                k = Math.min(n - e + 1, w - i)
                j = index_of(vector, k, i)
                if j == 0
                  [
                    [(i + 1), e]
                  ]
                else if j == 1
                  [
                    [i, (e + 1)]
                    [i, (e + 1), true] # t-position
                    [(i + 1), (e + 1)]
                    [(i + j + 1), (e + j)]
                  ]
                else if j > 1
                  [
                    [i, (e + 1)]
                    [(i + 1), (e + 1)]
                    [(i + j + 1), (e + j)]
                  ]
                else
                  [
                    [i, (e + 1)]
                    [(i + 1), (e + 1)]
                  ]
              else
                if vector[i]
                  [
                    [(i + 2), e]
                  ]
                else
                  null
            else if i == w - 1
              if vector[i]
                [
                  [(i + 1), e]
                ]
              else
                [
                  [i, (e + 1)]
                  [(i + 1), (e + 1)]
                ]
            else # i == w
              [
                [w, (e + 1)]
              ]
          else
            if i <= w - 1 and t isnt true
              if vector[i]
                [
                  [(i + 1), n]
                ]
              else
                null
            else if i <= w - 2 and t is true # [i,e] is a t-position
              if vector[i]
                [
                  [(i + 2), n]
                ]
              else
                null
            else # i == w
              null

      when MERGE_AND_SPLIT then (n) ->
        ([i,e,s], vector, offset) ->
          i -= offset; w = vector.length
          if e == 0 < n
            if i <= w - 2
              if vector[i]
                [
                  [(i + 1), e]
                ]
              else
                [
                  [i, (e + 1)]
                  [i, (e + 1), true] # s-position
                  [(i + 1), (e + 1)]
                  [(i + 2), (e + 1)]
                ]
            else if i == w - 1
              if vector[i]
                [
                  [(i + 1), e]
                ]
              else
                [
                  [i, (e + 1)]
                  [i, (e + 1), true] # s-position
                  [(i + 1), (e + 1)]
                ]
            else # i == w
              [
                [w, (e + 1)]
              ]
          else if e < n
            if i <= w - 2
              if s isnt true
                if vector[i]
                  [
                    [(i + 1), e]
                  ]
                else
                  [
                    [i, (e + 1)]
                    [i, (e + 1), true] # s-position
                    [(i + 1), (e + 1)]
                    [(i + 2), (e + 1)]
                  ]
              else # [i,e] is an s-position
                [
                  [(i + 1), e]
                ]
            else if i == w - 1
              if s isnt true
                if vector[i]
                  [
                    [(i + 1), e]
                  ]
                else
                  [
                    [i, (e + 1)]
                    [i, (e + 1), true] # s-position
                    [(i + 1), (e + 1)]
                  ]
              else # [i,e] is an s-position
                [
                  [(i + 1), e]
                ]
            else # i == w
              [
                [w, (e + 1)]
              ]
          else
            if i <= w - 1
              if s isnt true
                if vector[i]
                  [
                    [(i + 1), n]
                  ]
                else
                  null
              else # [i,e] is an s-position
                [
                  [(i + 1), e]
                ]
            else # i == w
              null

    relabel = (state, offset) ->
      position[0] += offset for position in state
      return

    transition_for_state = (n) ->
      transition = transition_for_position(n)

      (state, vector) ->
        offset = state[0][0]
        state_prime = []

        for position in state
          next_state = transition(position, vector, offset)
          continue unless next_state
          Array::push.apply(state_prime, next_state)

        if state_prime.length > 0
          relabel(state_prime, offset)
          state_prime
        else
          null

    dictionary.sort() unless sorted
    dawg = new Dawg(dictionary)

    characteristic_vector = (x, term, k, i) ->
      vector = []; j = 0
      while j < k
        vector.push(x is term[i + j])
        j += 1
      vector

    is_final =
      if algorithm is STANDARD
        (state, w, n) ->
          for [i,e] in state
            return true if w - i <= n - e
          return false
      else
        (state, w, n) ->
          for [i,e,x] in state
            return true if x isnt true and (w - i) <= (n - e)
          return false

    (term, n) ->
      w = term.length
      transition = transition_for_state(n)
      matches = []; stack = [['', dawg.root, [[0,0]]]]
      while stack.length > 0
        [V, q_D, M] = stack.pop(); i = M[0][0]; k = Math.min(2 * n + 1, w - i)
        for x, next_q_D of q_D.edges
          vector = characteristic_vector(x, term, k, i)
          next_M = transition(M, vector)
          if next_M
            next_V = V + x
            stack.push([next_V, next_q_D, next_M])
            if next_q_D.final and is_final(next_M, w, n)
              matches.push(next_V)
      matches

  if typeof exports isnt 'undefined'
    exports.transducer = transducer
  else if typeof levenshtein isnt 'undefined'
    levenshtein.transducer = transducer
  else
    throw new Error('Cannot find either the "levenshtein" or "exports" variable')

