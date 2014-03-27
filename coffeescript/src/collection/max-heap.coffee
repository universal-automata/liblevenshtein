class MaxHeap
  _parent: (i) ->
    # Index of the parent of the element of A, having the index, i
    if i > 0 then ((i + 1) >> 1) - 1 else 0
  _left_child: (i) ->
    # Index of the left child of the element of A, having the index, i
    (i << 1) + 1
  _right_child: (i) ->
    # Index of the right child of the element of A, having the index, i
    (i << 1) + 2
  _heapify: (i) ->
    # Modifies the heap array, A, such that its index, i, points to the root of
    # a sub-heap.
    l = @_left_child(i)
    r = @_right_child(i)
    heap = @['heap']
    if l < @['length'] and @f(heap[l], heap[i]) > 0
      largest = l
    else
      largest = i
    if r < @['length'] and @f(heap[r], heap[largest]) > 0
      largest = r
    if largest isnt i
      tmp = heap[i]
      heap[i] = heap[largest]
      heap[largest] = tmp
      @_heapify(largest)
    null
  _build: () ->
    i = @['length'] >> 1
    while i >= 0
      @_heapify(i)
      i -= 1
    null
  'increase_key': (i, key) ->
    f = @f
    heap = @['heap']
    if f(key, heap[i]) < 0
      throw new Error("Expected #{key} to be at least heap[#{i}] = #{heap[i]}")
    heap[i] = key
    parent = @_parent
    p = parent(i)
    while i and f(heap[p], heap[i]) < 0
      tmp = heap[i]
      heap[i] = heap[p]
      heap[p] = tmp
      i = p
      p = parent(i)
    null
  'sort': () ->
    @_build()
    i = @['length'] - 1
    heap = @['heap']
    while i >= 0
      tmp = heap[0]
      heap[0] = heap[i]
      heap[i] = tmp
      @['length'] -= 1
      @_heapify(0)
      i -= 1
    null
  'peek': () ->
    if @['length']
      @['heap'][0]
    else
      null
  'pop': () ->
    if @['length']
      heap = @['heap']
      max = heap[0]
      heap[0] = heap[@['length'] - 1]
      @['length'] -= 1
      @_heapify(0)
      max
    else
      null
  'push': (key) ->
    i = @['length']
    @['length'] += 1
    parent = @_parent
    p = parent(i)
    heap = @['heap']
    f = @f
    while i > 0 and f(heap[p], key) < 0
      heap[i] = heap[p]
      i = p
      p = parent(i)
    heap[i] = key
    null
  constructor: (f, heap, length) ->
    heap = [] unless heap
    unless typeof heap.length is 'number'
      throw new Error("heap must be array-like")
    unless typeof length is 'number'
      length = if heap then heap.length else 0
    unless typeof f is 'function'
      throw new Error("f must be a function")
    unless 0 <= length <= heap.length
      throw new Error("Expected 0 <= heap length = #{length} <= #{heap.length} = heap size")
    @f = f
    @['heap'] = heap
    @['length'] = length
    @_build()

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['MaxHeap'] = MaxHeap
