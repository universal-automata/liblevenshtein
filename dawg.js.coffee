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
      (if @final then '1' else '0') + edges.join('')

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
      # Find longest common prefix between word and previous word
      i = 0; previous_word = @previous_word

      upper_bound = Math.min(word.length, previous_word.length)
      i += 1 while i < upper_bound and word[i] is previous_word[i]

      # Check the unchecked_nodes for redundant nodes, proceeding from last one
      # down to the common prefix size.  Then truncate the list at that point.
      @minimize(i)
      unchecked_nodes = @unchecked_nodes

      # Add the suffix, starting from the correct node mid-way through the graph.
      if unchecked_nodes.length is 0
        node = @root
      else
        node = unchecked_nodes[unchecked_nodes.length - 1][2]

      while character = word[i]
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

      j = unchecked_nodes.length
      while j > lower_bound
        [parent, character, child] = unchecked_nodes.pop()
        child_key = child.toString()
        if child_key of minimized_nodes
          # replace the child with the previously encountered one
          parent.edges[character] = minimized_nodes[child_key]
        else
          # add the state to the minimized nodes
          minimized_nodes[child_key] = child
        j -= 1
      return

    accepts: (word) ->
      node = @root
      for edge in word
        node = node.edges[edge]
        return false unless node
      node.final

  if typeof exports isnt 'undefined'
    exports.DawgNode = DawgNode
    exports.Dawg = Dawg
  else if typeof levenshtein isnt 'undefined'
    levenshtein.DawgNode = DawgNode
    levenshtein.Dawg = Dawg
  else
    throw new Error('Cannot find either the "levenshtein" or "exports" variable')

