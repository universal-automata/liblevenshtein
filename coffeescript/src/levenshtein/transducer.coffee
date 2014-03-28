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
class Transducer
  # Accepts a state corresponding to some dictionary term and the length of the
  # query term, and identifies the minimum distance between the terms.
  'minimum_distance': (state, w) ->
    throw new Error('minimum_distance not specified on construction')

  # Returns a collection for storing spelling candidates. The only requirement
  # is that it has a push(candidate) method and can be passed to
  # this.transform(matches)
  'build_matches': () ->
    throw new Error('build_matches not specified on construction')

  # Returns the initial state of the Levenshtein automaton
  'initial_state': () ->
    throw new Error('initial_state not specified on construction')

  # Returns the root of the dictionary
  'root': () ->
    throw new Error('root not specified on construction')

  # Returns a mapping of labels to dictionary states, which correspond to the
  # outgoing edges of a dictionary state.
  'edges': (q_D) ->
    throw new Error('edges not specified on construction')

  # Determines whether a dictionary state is final
  'is_final': (q_D) ->
    throw new Error('is_final not specified on construction')

  # Transforms a collection of spelling candidates as necessary
  'transform': (matches) ->
    throw new Error('transform not specified on construction')

  # Accepts the maximum edit distance and returns a function that transitions
  # among states.
  'transition_for_state': (n) ->
    throw new Error('transition_for_state not specified on construction')

  # Returns the characteristic vector of a set of parameters (see the paper,
  # "Fast String Correction with Levenshtein-Automata")
  'characteristic_vector': (x, term, k, i) ->
    throw new Error('characteristic_vector not specified on construction')

  # Pushes a spelling candidate onto the matches
  'push': (matches, candidate) ->
    throw new Error('push not specified on construction')

  # Specifies the default, maximum edit distance a spelling candidate may be
  # from a query term.
  'default_edit_distance': () ->
    throw new Error('default_edit_distance not specified on construction')

  constructor: (attributes) ->
    for own attribute of attributes
      this[attribute] = attributes[attribute]

  # Returns every term in the dictionary that is within n units of error from
  # the query term.
  'transduce': (term, n) ->
    n = @['default_edit_distance']() unless typeof n is 'number'
    w = term.length
    transition = @['transition_for_state'](n)
    matches = @['build_matches']()
    stack = [['', @['root'](), @['initial_state']()]]
    while stack.length > 0
      [V, q_D, M] = stack['pop'](); i = M[0][0]
      a = 2 * n + 1; b = w - i
      k = if a < b then a else b
      for x, next_q_D of @['edges'](q_D)
        vector = @['characteristic_vector'](x, term, k, i)
        next_M = transition(M, vector)
        if next_M
          next_V = V + x
          stack.push([next_V, next_q_D, next_M])
          if @['is_final'](next_q_D)
            distance = @['minimum_distance'](next_M, w)
            if distance <= n
              @['push'](matches, [next_V, distance])
    @['transform'](matches)

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['Transducer'] = Transducer

