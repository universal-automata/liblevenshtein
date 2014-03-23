global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

concat = (lists...) ->
  concatenation = []
  (concatenation = concatenation.concat(list)) for list in lists
  concatenation

expand = (element, lists) ->
  list.unshift(element) for list in lists
  lists

swap = (list, i, j) ->
  t = list[i]
  list[i] = list[j]
  list[j] = t
  list

permutations = (list, i) ->
  switch list.length - i
    when 0
      []
    when 1
      [[list[i]]]
    when 2
      [
        [list[i], list[i + 1]]
        [list[i + 1], list[i]]
      ]
    else
      p = []
      offset = list.length - i
      for j in [0...offset]
        l = list.slice()
        swap(l, i, i + j)
        p.push(expand(l[i], permutations(l, i + 1)))
      concat.apply(null, p)

global.permutations = (list) -> permutations(list, 0)
