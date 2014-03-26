truth_table = (n, i=0, truths=[], buffer=[]) ->
  if i < n
    for truth in [true, false]
      truths[i] = truth
      truth_table(n, 1 + i, truths, buffer)
  else
    buffer.push truths
  buffer

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['truth_table'] = truth_table
