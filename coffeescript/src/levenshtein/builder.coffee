if typeof require is 'function'
  {levenshtein: {MinHeap}} = require '../collection/min-heap'
  {levenshtein: {Transducer}} = require './transducer'
  {levenshtein: {Dawg}} = require '../collection/dawg'
else
  {MinHeap, Transducer, Dawg} = levenshtein

class Builder
  _dictionary: []
  _algorithm: 'standard'
  _sort_matches: true
  _case_insensitive_sort: true
  _include_distance: true

  constructor: (source) ->
    if source
      unless source instanceof Builder
        throw new Error('Expected source to be an instance of Builder')
      @_dictionary = source._dictionary
      @_algorithm = source._algorithm
      @_sort_matches = source._sort_matches
      @_case_insensitive_sort = source._case_insensitive_sort
      @_include_distance = source._include_distance

  _build: (attributes) ->
    builder = new Builder()
    builder._dictionary = @_dictionary
    builder._algorithm = @_algorithm
    builder._sort_matches = @_sort_matches
    builder._case_insensitive_sort = @_case_insensitive_sort
    builder._include_distance = @_include_distance
    for own attribute, value of attributes
      builder['_' + attribute] = value
    builder

  dictionary: (dictionary, sorted) ->
    if dictionary is `undefined`
      @_dictionary
    else
      unless dictionary instanceof Array or dictionary instanceof Dawg
        throw new Error('dictionary must be either an Array or Dawg')
      if dictionary instanceof Array
        dictionary.sort() unless sorted
        dictionary = new Dawg(dictionary)
      @_build(dictionary: dictionary)

  algorithm: (algorithm) ->
    if algorithm is `undefined`
      @_algorithm
    else
      unless algorithm in ['standard', 'transposition', 'merge_and_split']
        throw new Error(
          'algorithm must be standard, transposition, or merge_and_split')
      @_build(algorithm: algorithm)

  sort_matches: (sort_matches) ->
    if sort_matches is `undefined`
      @_sort_matches
    else
      unless typeof sort_matches is 'boolean'
        throw new Error('sort_matches must be a boolean')
      @_build(sort_matches: sort_matches)

  case_insensitive_sort: (case_insensitive_sort) ->
    if case_insensitive_sort is `undefined`
      @_case_insensitive_sort
    else
      unless typeof case_insensitive_sort is 'boolean'
        throw new Error('case_insensitive_sort must be a boolean')
      @_build(case_insensitive_sort: case_insensitive_sort)

  include_distance: (include_distance) ->
    if include_distance is `undefined`
      @_include_distance
    else
      unless typeof include_distance is 'boolean'
        throw new Error('include_distance must be a boolean')
      @_build(include_distance: include_distance)

  # The distance of each position in a state can be defined as follows:
  #
  #   distance = w - i + e
  #
  # For every accepting position, it must be the case that w - i <= n - e.  It
  # follows directly that the distance of every accepted position must be no
  # more than n:
  #
  # (w - i <= n - e) <=> (w - i + e <= n) <=> (distance <= n)
  #
  # The Levenshtein distance between any two terms is defined as the minimum
  # edit distance between the two terms.  Therefore, iterate over each position
  # in an accepting state, and take the minimum distance among all its accepting
  # positions as the corresponding Levenshtein distance.
  _minimum_distance: () ->
    if @algorithm() is 'standard'
      (state, w) ->
        minimum = Infinity
        for [i,e] in state
          distance = w - i + e
          minimum = distance if distance < minimum
        minimum
    else
      (state, w) ->
        minimum = Infinity
        for [i,e,x] in state
          distance = w - i + e
          minimum = distance if x isnt 1 and distance < minimum
        minimum

  _comparator: () ->
    if @sort_matches()
      # Sort by minimum distance from the query term.
      comparator = (a,b) -> a[1] - b[1]
      # Sort in a case-insensitive manner.
      comparator = do(comparator) ->
        (a,b) ->
          comparator() || a.toLowerCase().localeCompare(b.toLowerCase())
      # If the terms are the same, case-insensitive, then compare them in a
      # case-sensitive manner.
      unless @case_insensitive_sort()
        comparator = do(comparator) ->
          (a,b) ->
            comparator() || a.localeCompare(b)
    else
      () -> 0 #-> If we don't want to sort the matches, make all terms equal

  _map: (comparator, matches, transform) ->
    heap = new MinHeap(comparator, matches)
    unless @include_distance()
      heap.peek = do(peek=heap.peek) ->
        () -> transform peek.call(heap)
      heap.pop = do(pop=heap.pop) ->
        () -> transform pop.call(heap)
    heap

  _initial_state: () ->
    if @algorithm() is 'standard'
      [[0,0]]
    else
      [[0,0,0]]

  # Accepts a state vector and sorts its elements in ascending order.
  _sort_for_transition: () ->
    comparator = (a,b) -> a[0] - b[0] || a[1] - b[1]
    if @algorithm() in ['transposition', 'merge_and_split']
      comparator = do (comparator) ->
        (a,b) -> comparator(a,b) || a[2] - b[2]
    (state) -> state.sort(comparator)

  _index_of: (vector, k, i) ->
    j = 0
    while j < k
      return j if vector[i + j]
      j += 1
    return -1

  # Accepts a maximum edit distance and returns a transition function that maps
  # a position, state vector and table offset of the current state to its next
  # state.
  _transition_for_position: () ->
    switch @algorithm()
      when 'standard' then (n) =>
        ([i,e], vector, offset) =>
          h = i - offset; w = vector.length
          if e < n
            if h <= w - 2
              a = n - e + 1; b = w - h
              k = if a < b then a else b
              j = @_index_of(vector, k, h)
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

      when 'transposition' then (n) =>
        ([i,e,t], vector, offset) =>
          h = i - offset; w = vector.length
          if e == 0 < n
            if h <= w - 2
              a = n - e + 1; b = w - h
              k = if a < b then a else b
              j = @_index_of(vector, k, h)
              if j == 0
                [
                  [(i + 1), 0, 0]
                ]
              else if j == 1
                [
                  [i, 1, 0]
                  [i, 1, 1] # t-position
                  [(i + 1), 1, 0]
                  [(i + 2), 1, 0] # was [(i + j + 1), j, 0], but j=1
                ]
              else if j > 1
                [
                  [i, 1, 0]
                  [(i + 1), 1, 0]
                  [(i + j + 1), j, 0]
                ]
              else
                [
                  [i, 1, 0]
                  [(i + 1), 1, 0]
                ]
            else if h == w - 1
              if vector[h]
                [
                  [(i + 1), 0, 0]
                ]
              else
                [
                  [i, 1, 0]
                  [(i + 1), 1, 0]
                ]
            else # h == w
              [
                [i, 1, 0]
              ]
          else if 1 <= e < n
            if h <= w - 2
              if t is 0 # [i,e] is not a t-position
                a = n - e + 1; b = w - h
                k = if a < b then a else b
                j = @_index_of(vector, k, h)
                if j == 0
                  [
                    [(i + 1), e, 0]
                  ]
                else if j == 1
                  [
                    [i, (e + 1), 0]
                    [i, (e + 1), 1] # t-position
                    [(i + 1), (e + 1), 0]
                    [(i + 2), (e + 1), 0] # was [(i + j + 1), (e + j), 0], but j=1
                  ]
                else if j > 1
                  [
                    [i, (e + 1), 0]
                    [(i + 1), (e + 1), 0]
                    [(i + j + 1), (e + j), 0]
                  ]
                else
                  [
                    [i, (e + 1), 0]
                    [(i + 1), (e + 1), 0]
                  ]
              else
                if vector[h]
                  [
                    [(i + 2), e, 0]
                  ]
                else
                  null
            else if h == w - 1
              if vector[h]
                [
                  [(i + 1), e, 0]
                ]
              else
                [
                  [i, (e + 1), 0]
                  [(i + 1), (e + 1), 0]
                ]
            else # h == w
              [
                [i, (e + 1), 0]
              ]
          else
            if h <= w - 1 and t is 0
              if vector[h]
                [
                  [(i + 1), n, 0]
                ]
              else
                null
            else if h <= w - 2 and t is 1 # [i,e] is a t-position
              if vector[h]
                [
                  [(i + 2), n, 0]
                ]
              else
                null
            else # h == w
              null

      when 'merge_and_split' then (n) =>
        ([i,e,s], vector, offset) =>
          h = i - offset; w = vector.length
          if e == 0 < n
            if h <= w - 2
              if vector[h]
                [
                  [(i + 1), e, 0]
                ]
              else
                [
                  [i, (e + 1), 0]
                  [i, (e + 1), 1] # s-position
                  [(i + 1), (e + 1), 0]
                  [(i + 2), (e + 1), 0]
                ]
            else if h == w - 1
              if vector[h]
                [
                  [(i + 1), e, 0]
                ]
              else
                [
                  [i, (e + 1), 0]
                  [i, (e + 1), 1] # s-position
                  [(i + 1), (e + 1), 0]
                ]
            else # h == w
              [
                [i, (e + 1), 0]
              ]
          else if e < n
            if h <= w - 2
              if s is 0
                if vector[h]
                  [
                    [(i + 1), e, 0]
                  ]
                else
                  [
                    [i, (e + 1), 0]
                    [i, (e + 1), 1] # s-position
                    [(i + 1), (e + 1), 0]
                    [(i + 2), (e + 1), 0]
                  ]
              else # [i,e] is an s-position
                [
                  [(i + 1), e, 0]
                ]
            else if h == w - 1
              if s is 0
                if vector[h]
                  [
                    [(i + 1), e, 0]
                  ]
                else
                  [
                    [i, (e + 1), 0]
                    [i, (e + 1), 1] # s-position
                    [(i + 1), (e + 1), 0]
                  ]
              else # [i,e] is an s-position
                [
                  [(i + 1), e, 0]
                ]
            else # h == w
              [
                [i, (e + 1), 0]
              ]
          else
            if h <= w - 1
              if s is 0
                if vector[h]
                  [
                    [(i + 1), n, 0]
                  ]
                else
                  null
              else # [i,e] is an s-position
                [
                  [(i + 1), e, 0]
                ]
            else # h == w
              null

  # Given two positions [i,e] and [j,f], for [i,e] to subsume [j,f], it must be
  # the case that e < f.  Therefore, I can remove a redundant check for (e < f)
  # within the subsumes method by finding the first index that contains a
  # position having an error greater than the current one (assuming that the
  # positions are sorted in ascending order, according to error).
  _bisect_error_right: (state, e, l) ->
    u = state.length
    while l < u
      i = (l + u) >> 1
      if e < state[i][1]
        u = i
      else
        l = i + 1
    return l

  # Removes all subsumed positions from a state
  _unsubsume: () =>
    subsumes = @_subsumes()
    bisect_error_right = @_bisect_error_right
    switch @algorithm()
      when 'standard'
        (state) ->
          m = 0
          while x = state[m]
            [i,e] = x; n = bisect_error_right(state, e, m)
            while y = state[n]
              [j,f] = y
              if subsumes(i,e, j,f)
                state.splice(n,1)
              else
                n += 1
            m += 1
          return
      when 'transposition'
        (state) ->
          m = 0
          while x = state[m]
            [i,e,s] = x; n = bisect_error_right(state, e, m)
            while y = state[n]
              [j,f,t] = y
              if subsumes(i,e,s, j,f,t, n)
                state.splice(n,1)
              else
                n += 1
            m += 1
          return
      when 'merge_and_split'
        (state) ->
          m = 0
          while x = state[m]
            [i,e,s] = x; n = bisect_error_right(state, e, m)
            while y = state[n]
              [j,f,t] = y
              if subsumes(i,e,s, j,f,t, n)
                state.splice(n,1)
              else
                n += 1
            m += 1
          return

  # NOTE: See my comment above bisect_error_right(state,e,l) and how I am using
  # it in _unsubsume for why I am not checking (e < f) below.
  _subsumes: () ->
    switch @algorithm()
      when 'standard' then (i,e, j,f) ->
        #(e < f) && Math.abs(j - i) <= (f - e)
        ((i < j) && (j - i) || (i - j)) <= (f - e)
      when 'transposition' then (i,e,s, j,f,t, n) ->
        if s is 1
          if t is 1
            #(e < f) && (i == j)
            (i == j)
          else
            #(e < f == n) && (i == j)
            (f == n) && (i == j)
        else
          if t is 1
            #(e < f) && Math.abs(j - (i - 1)) <= (f - e)
            #
            # NOTE: This is how I derived what follows:
            #   Math.abs(j - (i - 1)) = Math.abs(j - i + 1) = Math.abs(j - i) + 1
            #
            ((i < j) && (j - i) || (i - j)) + 1 <= (f - e)
          else
            #(e < f) && Math.abs(j - i) <= (f - e)
            ((i < j) && (j - i) || (i - j)) <= (f - e)
      when 'merge_and_split' then(i,e,s, j,f,t) ->
        if s is 1 and t is 0
          false
        else
          #(e < f) && Math.abs(j - i) <= (f - e)
          ((i < j) && (j - i) || (i - j)) <= (f - e)

  _bisect_left: () ->
    if @algorithm() is 'standard'
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

  # Merges the positions of next_state into state_prime, in a
  # subsumption-friendly manner.
  _merge_for_subsumption: () ->
    bisect_left = @_bisect_left()
    if @algorithm() is 'standard'
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

  _transition_for_state: () ->
    merge_for_subsumption = @_merge_for_subsumption()
    unsubsume = @_unsubsume()
    transition_for_position = @_transition_for_position()
    sort_for_transition = @_sort_for_transition()
    (n) ->
      transition = transition_for_position(n)
      (state, vector) =>
        offset = state[0][0]; state_prime = []

        for position in state
          next_state = transition(position, vector, offset)
          continue unless next_state
          merge_for_subsumption(state_prime, next_state)
        unsubsume(state_prime)

        if state_prime.length > 0
          sort_for_transition(state_prime)
          state_prime
        else
          null

  _characteristic_vector: () ->
    (x, term, k, i) ->
      vector = []; j = 0
      while j < k
        vector.push(x is term[i + j])
        j += 1
      vector

  transducer: () ->
    new Transducer({
      minimum_distance: @_minimum_distance()
      build_matches: () -> []
      transition_for_state: @_transition_for_state()
      characteristic_vector: @_characteristic_vector()
      edges: (dawg_node) -> dawg_node['edges']
      is_final: (dawg_node) -> dawg_node['is_final']
      root: do (dawg = @dictionary()) ->
        () -> dawg['root']
      initial_state: do (initial_state=@_initial_state()) ->
        () => initial_state
      transform: do (comparator = @_comparator()) =>
        (matches) =>
          @_map(comparator, matches, (pair) -> pair[0])
    })

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['Builder'] = Builder
