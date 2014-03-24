###*
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
###
transducer = (args) ->
  dictionary       = args['dictionary']
  sorted           = args['sorted']
  dictionary_type  = args['dictionary_type']
  algorithm        = args['algorithm']
  sort_matches     = args['sort_matches']
  include_distance = args['include_distance']
  case_insensitive = args['case_insensitive']

  throw new Error('No dictionary was specified') unless dictionary
  unless dictionary instanceof Array or dictionary instanceof Dawg
    throw new Error('dictionary must be either an Array or levenshtein.Dawg')

  sorted = false unless typeof sorted is 'boolean'
  dictionary_type = 'list' unless dictionary_type in ['list', 'dawg']
  algorithm = 'standard' unless algorithm in ['standard', 'transposition', 'merge_and_split']
  sort_matches = true unless typeof sort_matches is 'boolean'
  include_distance = true unless typeof include_distance is 'boolean'
  case_insensitive = true unless typeof case_insensitive is 'boolean'

  index_of = (vector, k, i) ->
    j = 0
    while j < k
      return j if vector[i + j]
      j += 1
    return -1

  transition_for_position = switch algorithm
    when 'standard' then (n) ->
      ([i,e], vector, offset) ->
        h = i - offset; w = vector.length
        if e < n
          if h <= w - 2
            a = n - e + 1; b = w - h
            k = if a < b then a else b
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

    when 'transposition' then (n) ->
      ([i,e,t], vector, offset) ->
        h = i - offset; w = vector.length
        if e == 0 < n
          if h <= w - 2
            a = n - e + 1; b = w - h
            k = if a < b then a else b
            j = index_of(vector, k, h)
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
              j = index_of(vector, k, h)
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

    when 'merge_and_split' then (n) ->
      ([i,e,s], vector, offset) ->
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

  bisect_left =
    if algorithm is 'standard'
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
    if algorithm is 'standard'
      (state) -> ([i,e] for [i,e] in state)
    else
      (state) -> ([i,e,x] for [i,e,x] in state)

  # NOTE: See my comment above bisect_error_right(state,e,l) and how I am
  # using it in unsubsume_for(n) for why I am not checking (e < f) below.
  subsumes = switch algorithm
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

  # Given two positions [i,e] and [j,f], for [i,e] to subsume [j,f], it must
  # be the case that e < f.  Therefore, I can remove a redundant check for
  # (e < f) within the subsumes method by finding the first index that
  # contains a position having an error greater than the current one (assuming
  # that the positions are sorted in ascending order, according to error).
  bisect_error_right = (state, e, l) ->
    u = state.length
    while l < u
      i = (l + u) >> 1
      if e < state[i][1]
        u = i
      else
        l = i + 1
    return l

  unsubsume_for = switch algorithm
    when 'standard' then (n) ->
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
    when 'transposition' then (n) ->
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
    when 'merge_and_split' then (n) ->
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

  stringify_state =
    if algorithm is 'standard'
      (state) ->
        signature = ''
        for [i,e] in state
          signature += i.toString() + ',' + e.toString()
        signature
    else
      (state) ->
        signature = ''
        for [i,e,x] in state
          signature += i.toString() + ',' + e.toString() + ',' + x.toString()
        signature

  insert_for_subsumption =
    if algorithm is 'standard'
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

  sort_for_transition =
    if algorithm is 'standard'
      (state) ->
        state.sort (a,b) -> a[0] - b[0] || a[1] - b[1]
        return
    else
      (state) ->
        state.sort (a,b) -> a[0] - b[0] || a[1] - b[1] || a[2] - b[2]
        return

  transition_for_state = (n) ->
    transition = transition_for_position(n)
    unsubsume = unsubsume_for(n)

    (state, vector) ->
      offset = state[0][0]; state_prime = []

      for position in state
        next_state = transition(position, vector, offset)
        continue unless next_state
        insert_for_subsumption(state_prime, next_state)
      unsubsume(state_prime)

      if state_prime.length > 0
        sort_for_transition(state_prime)
        state_prime
      else
        null

  if dictionary_type is 'list'
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
    if algorithm is 'standard'
      (state, w, n) ->
        for [i,e] in state
          return true if (w - i) <= (n - e)
        return false
    else
      (state, w, n) ->
        for [i,e,x] in state
          return true if x isnt 1 and (w - i) <= (n - e)
        return false

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
  minimum_distance =
    if algorithm is 'standard'
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

  insert_match =
    if sort_matches
      if include_distance
        if case_insensitive
          (matches, match, distance) ->
            l = 0; u = matches.length; downcased = match.toLowerCase()
            while l < u
              i = (l + u) >> 1; [w,d] = matches[i]
              if (d - distance || w.toLowerCase().localeCompare(downcased)) < 0
                l = i + 1
              else
                u = i
            matches.splice(l, 0, [match, distance])
        else
          (matches, match, distance) ->
            l = 0; u = matches.length
            while l < u
              i = (l + u) >> 1; [w,d] = matches[i]
              if (d - distance || w.localeCompare(match)) < 0
                l = i + 1
              else
                u = i
            matches.splice(l, 0, [match, distance])
      else
        if case_insensitive
          (matches, match) ->
            l = 0; u = matches.length; downcased = match.toLowerCase()
            while l < u
              i = (l + u) >> 1; [w,d] = matches[i]
              if w.toLowerCase().localeCompare(downcased) < 0
                l = i + 1
              else
                u = i
            matches.splice(l, 0, match)
        else
          (matches, match) ->
            l = 0; u = matches.length
            while l < u
              i = (l + u) >> 1; [w,d] = matches[i]
              if w.localeCompare(match) < 0
                l = i + 1
              else
                u = i
            matches.splice(l, 0, match)
    else
      if include_distance
        (matches, match, distance) -> matches.push([match, distance])
      else
        (matches, match) -> matches.push(match)

  initial_state =
    if algorithm is 'standard'
      [[0,0]]
    else
      [[0,0,0]]

  if include_distance
    (term, n) ->
      w = term.length
      transition = transition_for_state(n)
      matches = []; stack = [['', dawg['root'], initial_state]]
      while stack.length > 0
        [V, q_D, M] = stack.pop(); i = M[0][0]
        a = 2 * n + 1; b = w - i
        k = if a < b then a else b
        for x, next_q_D of q_D['edges']
          vector = characteristic_vector(x, term, k, i)
          next_M = transition(M, vector)
          if next_M
            next_V = V + x
            stack.push([next_V, next_q_D, next_M])
            if next_q_D['is_final'] and (distance = minimum_distance(next_M, w)) <= n
              insert_match(matches, next_V, distance)
      matches
  else
    (term, n) ->
      w = term.length
      transition = transition_for_state(n)
      matches = []; stack = [['', dawg['root'], initial_state]]
      while stack.length > 0
        [V, q_D, M] = stack.pop(); i = M[0][0]
        a = 2 * n + 1; b = w - i
        k = if a < b then a else b
        for x, next_q_D of q_D['edges']
          vector = characteristic_vector(x, term, k, i)
          next_M = transition(M, vector)
          if next_M
            next_V = V + x
            stack.push([next_V, next_q_D, next_M])
            if next_q_D['is_final'] and is_final(next_M, w, n)
              insert_match(matches, next_V)
      matches

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['transducer'] = transducer

