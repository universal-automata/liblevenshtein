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

  LIST = 'list'
  DAWG = 'dawg'

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
  transducer = ({dictionary, sorted, dictionary_type, algorithm}) ->
    sorted = false unless typeof sorted is 'boolean'
    dictionary_type = LIST unless dictionary_type in [LIST, DAWG]
    algorithm = STANDARD unless algorithm in [STANDARD, TRANSPOSITION, MERGE_AND_SPLIT]

    index_of = (vector, k, i) ->
      j = 0
      while j < k
        return j if vector[i + j]
        j += 1
      return -1

    transition_for_position = switch algorithm
      when STANDARD then (n) ->
        ([i,e], vector, offset) ->
          h = i - offset; w = vector.length
          if e < n
            if h <= w - 2
              k = Math.min(n - e + 1, w - h)
              j = index_of(vector, k, h)
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
            else if h == w - 1
              if vector[h]
                [
                  [(i + 1), e]
                ]
              else
                [
                  [i, (e + 1)]
                  [(i + 1), (e + 1)]
                ]
            else # h == w
              [
                [i, (e + 1)]
              ]
          else if e == n
            if h <= w - 1
              if vector[h]
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
          h = i - offset; w = vector.length
          if e == 0 < n
            if h <= w - 2
              k = Math.min(n - e + 1, w - h)
              j = index_of(vector, k, h)
              if j == 0
                [
                  [(i + 1), 0]
                ]
              else if j == 1
                [
                  [i, 1]
                  [i, 1, true] # t-position
                  [(i + 1), 1]
                  [(i + 2), 1]
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
            else if h == w - 1
              if vector[h]
                [
                  [(i + 1), 0]
                ]
              else
                [
                  [i, 1]
                  [(i + 1), 1]
                ]
            else # h == w
              [
                [i, 1]
              ]
          else if 1 <= e < n
            if h <= w - 2
              if t isnt true # [i,e] is not a t-position
                k = Math.min(n - e + 1, w - h)
                j = index_of(vector, k, h)
                if j == 0
                  [
                    [(i + 1), e]
                  ]
                else if j == 1
                  [
                    [i, (e + 1)]
                    [i, (e + 1), true] # t-position
                    [(i + 1), (e + 1)]
                    [(i + 2), (e + 1)]
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
                if vector[h]
                  [
                    [(i + 2), e]
                  ]
                else
                  null
            else if h == w - 1
              if vector[h]
                [
                  [(i + 1), e]
                ]
              else
                [
                  [i, (e + 1)]
                  [(i + 1), (e + 1)]
                ]
            else # h == w
              [
                [i, (e + 1)]
              ]
          else
            if h <= w - 1 and t isnt true
              if vector[h]
                [
                  [(i + 1), n]
                ]
              else
                null
            else if h <= w - 2 and t is true # [i,e] is a t-position
              if vector[h]
                [
                  [(i + 2), n]
                ]
              else
                null
            else # h == w
              null

      when MERGE_AND_SPLIT then (n) ->
        ([i,e,s], vector, offset) ->
          h = i - offset; w = vector.length
          if e == 0 < n
            if h <= w - 2
              if vector[h]
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
            else if h == w - 1
              if vector[h]
                [
                  [(i + 1), e]
                ]
              else
                [
                  [i, (e + 1)]
                  [i, (e + 1), true] # s-position
                  [(i + 1), (e + 1)]
                ]
            else # h == w
              [
                [i, (e + 1)]
              ]
          else if e < n
            if h <= w - 2
              if s isnt true
                if vector[h]
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
            else if h == w - 1
              if s isnt true
                if vector[h]
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
            else # h == w
              [
                [i, (e + 1)]
              ]
          else
            if h <= w - 1
              if s isnt true
                if vector[h]
                  [
                    [(i + 1), n]
                  ]
                else
                  null
              else # [i,e] is an s-position
                [
                  [(i + 1), e]
                ]
            else # h == w
              null

    #relabel = (state, offset) ->
      #position[0] += offset for position in state
      #return

    bisect_left =
      if algorithm is STANDARD
        (state, position) ->
          [i,e] = position; l = 0; u = state.length
          while l < u
            k = (l + u) >> 1
            p = state[k]
            if (e - p[1] || i - p[0]) > 0
              l = k + 1
            else
              u = k
          return l
      else
        (state, position) ->
          [i,e,x] = position; l = 0; u = state.length
          while l < u
            k = (l + u) >> 1
            p = state[k]
            if (e - p[1] || i - p[0] || x - p[2]) > 0
              l = k + 1
            else
              u = k
          return l

    copy =
      if algorithm is STANDARD
        (state) -> ([i,e] for [i,e] in state)
      else
        (state) -> ([i,e,x is true] for [i,e,x] in state)

    subsumes = switch algorithm
      when STANDARD then (i,e, j,f) ->
        (e < f) && Math.abs(j - i) <= (f - e)
      when TRANSPOSITION then (i,e,s, j,f,t, n) ->
        if s
          if t
            (f > e) && (i == j)
          else
            (n == f > e) && (i == j)
        else
          if t
            (f > e) && Math.abs(j - (i - 1)) <= (f - e)
          else
            (e < f) && Math.abs(j - i) <= (f - e)
      when MERGE_AND_SPLIT then(i,e,s, j,f,t) ->
        if s and not t
          false
        else
          (f > e) && Math.abs(j - i) <= (f - e)

    unsubsume_for = switch algorithm
      when STANDARD then (n) ->
        (state) ->
          m = 0
          while x = state[m]
            [i,e] = x; n = m + 1
            while y = state[n]
              [j,f] = y
              if subsumes(i,e, j,f)
                state.splice(n,1)
              else
                n += 1
            m += 1
      when TRANSPOSITION then (n) ->
        (state) ->
          m = 0
          while x = state[m]
            [i,e,s] = x; n = m + 1
            while y = state[n]
              [j,f,t] = y
              if subsumes(i,e,s, j,f,t, n)
                state.splice(n,1)
              else
                n += 1
            m += 1
      when MERGE_AND_SPLIT then (n) ->
        (state) ->
          m = 0
          while x = state[m]
            [i,e,s] = x; n = m + 1
            while y = state[n]
              [j,f,t] = y
              if subsumes(i,e,s, j,f,t, n)
                state.splice(n,1)
              else
                n += 1
            m += 1

    stringify_state =
      if algorithm is STANDARD
        (state) ->
          signature = ''
          for [i,e] in state
            signature += i.toString() + ',' + e.toString()
          signature
      else
        (state) ->
          signature = ''
          for [i,e,x] in state
            signature += i.toString() + ',' + e.toString() + ',' + (x is true).toString()
          signature

    insert_for_subsumption =
      if algorithm is STANDARD
        (state_prime, next_state) ->
          # Order according to error first, then boundary (both ascending).
          # While sorting the elements, remove any duplicates.
          for position in next_state
            i = bisect_left(state_prime, position)
            if curr = state_prime[i]
              if curr[0] != position[0] || curr[1] != position[1]
                state_prime.splice(i, 0, position)
            else
              state_prime.push(position)
          return
      else
        (state_prime, next_state) ->
          # Order according to error first, then boundary (both ascending).
          # While sorting the elements, remove any duplicates.
          for position in next_state
            i = bisect_left(state_prime, position)
            if curr = state_prime[i]
              if curr[0] != position[0] || curr[1] != position[1] || curr[2] != position[2]
                state_prime.splice(i, 0, position)
            else
              state_prime.push(position)
          return

    transition_for_state = (n) ->
      transition = transition_for_position(n)
      unsubsume = unsubsume_for(n)
      memoized_states = {}

      (state, vector) ->
        state_key = stringify_state(state); vector_key = vector.join('')

        unless memoized_vectors = memoized_states[state_key]
          memoized_vectors = memoized_states[state_key] = {}

        if (state_prime = memoized_vectors[vector_key]) isnt `undefined`
          state_prime
        else
          offset = state[0][0]; state_prime = []

          for position in state
            next_state = transition(position, vector, offset)
            continue unless next_state
            insert_for_subsumption(state_prime, next_state)
          unsubsume(state_prime)

          if state_prime.length > 0
            state_prime.sort (a,b) -> a[0] - b[0] || a[1] - b[1]
            #relabel(state_prime, offset)
            memoized_vectors[vector_key] = state_prime
          else
            memoized_vectors[vector_key] = null

    if dictionary_type is LIST
      if typeof exports isnt 'undefined'
        {Dawg} = require('./dawg')
      else
        Dawg = levenshtein.Dawg

      dictionary.sort() unless sorted
      dawg = new Dawg(dictionary)
    else
      dawg = dictionary

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

