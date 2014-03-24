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
    @['is_final'] = false
    @['edges'] = {}

  bisect_left: (edges, edge, lower, upper) ->
    while lower < upper
      i = (lower + upper) >> 1
      if edges[i] < edge
        lower = i + 1
      else
        upper = i
    return lower

  'toString': ->
    edges = []
    for label, node of @['edges'] # insertion sort
      edge = label + node.id.toString()
      edges.splice(@bisect_left(edges, edge, 0, edges.length), 0, edge)
    (+ @['is_final']) + edges.join('')

class Dawg
  constructor: (dictionary) ->
    unless dictionary and typeof dictionary.length is 'number'
      throw new Error("Expected dictionary to be array-like")

    @previous_word = ''
    @['root'] = new DawgNode()

    # Here is a list of nodes that have not been checked for duplication.
    @unchecked_nodes = []

    # Here is a list of unique nodes that have been checked for duplication.
    @minimized_nodes = {}

    @['insert'](word) for word in dictionary
    @finish()

  'insert': (word) ->
    # Find longest common prefix between word and previous word
    i = 0; previous_word = @previous_word

    upper_bound =
      if word.length < previous_word.length
        word.length
      else
        previous_word.length

    i += 1 while i < upper_bound and word[i] is previous_word[i]

    # Check the unchecked_nodes for redundant nodes, proceeding from last one
    # down to the common prefix size.  Then truncate the list at that point.
    @minimize(i)
    unchecked_nodes = @unchecked_nodes

    # Add the suffix, starting from the correct node mid-way through the graph.
    if unchecked_nodes.length is 0
      node = @['root']
    else
      node = unchecked_nodes[unchecked_nodes.length - 1][2]

    while (character = word[i]) isnt `undefined`
      next_node = new DawgNode()
      node['edges'][character] = next_node
      unchecked_nodes.push([node, character, next_node])
      node = next_node
      i += 1

    node['is_final'] = true
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

    j = unchecked_nodes.length
    while j > lower_bound
      [parent, character, child] = unchecked_nodes.pop()
      child_key = child.toString()
      if child_key of minimized_nodes
        # replace the child with the previously encountered one
        parent['edges'][character] = minimized_nodes[child_key]
      else
        # add the state to the minimized nodes
        minimized_nodes[child_key] = child
      j -= 1
    return

  'accepts': (word) ->
    node = @['root']
    for edge in word
      node = node['edges'][edge]
      return false unless node
    node['is_final']

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['DawgNode'] = DawgNode
global['levenshtein']['Dawg'] = Dawg

