global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}

if typeof require is 'function'
  {levenshtein: {MaxHeap}} = require '../collection/max-heap'
  {levenshtein: {Transducer}} = require './transducer'
  {levenshtein: {Dawg}} = require '../collection/dawg'
else
  MaxHeap = global['levenshtein']['MaxHeap']
  Transducer = global['levenshtein']['Transducer']
  Dawg = global['levenshtein']['Dawg']

fields =
  # Dictionary of terms
  '_dictionary': new Dawg([])
  # Search algorithm to use
  '_algorithm': 'standard'
  # Sort the candidates as they are discovered
  '_sort_candidates': true
  # If sort_candidates, then sort them in a case-insensitive fashion
  '_case_insensitive_sort': true
  # Include the distance from the query term for each spelling candidate
  '_include_distance': true
  # Maximum number of spelling candidates to return
  '_maximum_candidates': Infinity
  # Customer comparator for the max-heap (optional). This should be an arity-2
  # function that accepts two pairs of ["term", distance] values.
  '_custom_comparator': null
  # Custom transform for spelling candidates (optional). This should be an
  # arity-1 function that accepts a pair of ["term", distance] values.
  '_custom_transform': null
  # Maximum number of spelling errors that are tollerated. This can be
  # overridden with the second parameter to Transducer.transduce(term, n)
  '_default_edit_distance': Infinity

class Builder
  constructor: (source, attributes) ->
    if source instanceof Builder
      for own field of fields
        this[field] = source[field]
      for own attribute, value of attributes
        this['_' + attribute] = value

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
    if @['_algorithm'] is 'standard'
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
    if typeof @['_custom_comparator'] is 'function'
      @['_custom_comparator']
    else if @['_sort_candidates']
      # Sort by minimum distance from the query term.
      comparator = (a,b) -> a[1] - b[1]
      # Sort in a case-insensitive manner.
      comparator = do (comparator) ->
        (a,b) ->
          comparator(a,b) || a[0].toLowerCase().localeCompare(b[0].toLowerCase())
      # If the terms are the same, case-insensitive, then compare them in a
      # case-sensitive manner.
      unless @['_case_insensitive_sort']
        comparator = do (comparator) ->
          (a,b) ->
            comparator(a,b) || a[0].localeCompare(b[0])
      comparator
    else
      () -> 0 #-> If we don't want to sort the matches, make all terms equal

  _transform: (comparator) ->
    transform =
      if typeof @['_custom_transform'] is 'function'
        @['_custom_transform']
      else if @['_include_distance'] is false
        (candidate) -> candidate[0]

    (matches) =>
      if isFinite @['_maximum_candidates']
        matches['sort']() #-> sorts in reverse
        matches = matches['heap']
      else if @['_sort_candidates']
        heap = matches
        matches = []
        matches.push heap['pop']() while heap['peek']() isnt null
      if typeof transform is 'function'
        i = -1; while (++i) < matches.length
          matches[i] = transform(matches[i])
      matches

  _initial_state: () ->
    if @['_algorithm'] is 'standard'
      [[0,0]]
    else
      [[0,0,0]]

  # Accepts a state vector and sorts its elements in ascending order.
  _sort_for_transition: () ->
    comparator = (a,b) -> a[0] - b[0] || a[1] - b[1]
    if @['_algorithm'] in ['transposition', 'merge_and_split']
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
    switch @['_algorithm']
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
    switch @['_algorithm']
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
    switch @['_algorithm']
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
    if @['_algorithm']
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
    if @['_algorithm'] is 'standard'
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

  _push: (compare) ->
    maximum_candidates = @['_maximum_candidates']
    if isFinite maximum_candidates
      (candidates, candidate) ->
        if candidates.length is maximum_candidates
          # We are maintaining a max-heap so that the element furthest from the
          # query term will be on the top.  If the new candidate is closer to
          # the query term then it should replace the old one.
          if compare(candidate, candidates['peek']()) < 0
            candidates['pop']()
            candidates.push(candidate)
        else
          candidates.push(candidate)
        candidates
    else
      (candidates, candidate) ->
        candidates.push(candidate)
        candidates

  'build': () ->
    comparator = @_comparator()
    new Transducer({
      'minimum_distance': @_minimum_distance()
      'build_matches': do =>
        if isFinite @['_maximum_candidates']
          () -> new MaxHeap(comparator)
        else if @['_sort_candidates']
          () -> new MaxHeap (a,b) -> - comparator(a,b)
        else
          () -> []
      'transition_for_state': @_transition_for_state()
      'characteristic_vector': @_characteristic_vector()
      'edges': (dawg_node) -> dawg_node['edges']
      'is_final': (dawg_node) -> dawg_node['is_final']
      'root': do (dawg = @['_dictionary']) ->
        () -> dawg['root']
      'initial_state': do (initial_state=@_initial_state()) ->
        () => initial_state
      'push': @_push(comparator)
      'default_edit_distance': () => @['default_edit_distance']()
      'transform': @_transform(comparator)
    })

# Aliases Builder::transducer to Builder::build, for those who prefer the
# syntax, builder.transducer(), over builder.build()
Builder::['transducer'] = Builder::['build']

# Initialize the default, property values
for own property, value of fields
  Builder::[property] = value

# Performs no operation
noop = () -> return
# Identity function: returns whatever you give it
identity = (x) -> x

def_property = def_properties = (properties, params; property, i) ->
  [validate, translate] = [params['validate'], params['translate']]
  if typeof properties is 'string'
    properties = [properties]
  unless properties instanceof Array
    throw new Error('Expected "properties" to be of type Array')
  if validate isnt `undefined` and typeof validate isnt 'function'
    throw new Error('Expected "validate" to be of type Function')
  if translate isnt `undefined` and typeof translate isnt 'function'
    throw new Error('Expected "translate" to be of type Function')

  validate ||= noop
  translate ||= identity

  for property, i in properties
    if typeof property isnt 'string'
      throw new Error(
        "Expected property at index #{i} of properties to be of type String")
    do (property) ->
      field = '_' + property
      Builder::[property] =
        (value, opts...) ->
          if value is `undefined`
            @[field]
          else
            validate(value, opts, property)
            value = translate(value, opts, property)
            attributes = {}
            attributes[property] = value
            new Builder(this, attributes)
  true

def_property 'dictionary',
  'validate': (dictionary) ->
    unless dictionary instanceof Array or dictionary instanceof Dawg
      throw new Error('dictionary must be either an Array or Dawg')
  'translate': (dictionary, [sorted]) ->
    if dictionary instanceof Array
      dictionary.sort() unless sorted is true
      dictionary = new Dawg(dictionary)
    dictionary

def_property 'algorithm',
  'validate': (algorithm) ->
    unless algorithm in ['standard', 'transposition', 'merge_and_split']
      throw new Error(
        'algorithm must be standard, transposition, or merge_and_split')

def_properties ['sort_candidates', 'case_insensitive_sort', 'include_distance'],
  'validate': (value, _, property) ->
    unless typeof value is 'boolean'
      throw new Error("Expected type of \"#{property}\" to be boolean")

def_properties ['maximum_candidates', 'default_edit_distance'],
  'validate': (value, _, property) ->
    unless typeof value is 'number' and 0 <= value
      throw new Error("Expected \"#{property}\" to be a non-negative number")

def_properties ['custom_comparator', 'custom_transform'],
  'validate': (value, _, property) ->
    unless typeof value is 'function'
      throw new Error("Expected \"#{property}\" to be a function")

global['levenshtein']['Builder'] = Builder
