class MinHeap
  parent: (i) ->
    # Index of the parent of the element of A, having the index, i
    ((i + 1) >> 1) - 1
  left_child: (i) ->
    # Index of the left child of the element of A, having the index, i
    (i << 1) + 1
  right_child: (i) ->
    # Index of the right child of the element of A, having the index, i
    (i << 1) + 2
  heapify: (i) ->
    # Modifies the heap array, A, such that its index, i, points to the root of
    # a sub-heap.
    l = @left_child(i)
    r = @right_child(i)
    heap = @heap
    if l < @['length'] and @f(heap[l], heap[i]) < 0
      smallest = l
    else
      smallest = i
    if r < @['length'] and @f(heap[r], heap[smallest]) < 0
      smallest = r
    if smallest isnt i
      tmp = heap[i]
      heap[i] = heap[smallest]
      heap[smallest] = tmp
      @heapify(smallest)
    null
  build: () ->
    i = @['length'] >> 1
    while i >= 0
      @heapify(i)
      i -= 1
    null
  'decrease_key': (i, key) ->
    f = @f
    heap = @heap
    c = f(key, heap[i])
    if c > 0
      throw new Error("Expected #{key} to be at no more than heap[#{i}] = #{heap[i]}")
    heap[i] = key
    parent = @parent
    p = parent(i)
    while i and f(heap[p], heap[i]) > 0
      tmp = heap[i]
      heap[i] = heap[p]
      heap[p] = tmp
      i = p
      p = parent(i)
    null
  'sort': () ->
    @build()
    i = @['length'] - 1
    heap = @heap
    while i >= 0
      tmp = heap[0]
      heap[0] = heap[i]
      heap[i] = tmp
      @['length'] -= 1
      @heapify(0)
      i -= 1
    null
  'peek': () ->
    if @['length']
      @heap[0]
    else
      null
  'pop': () ->
    if @['length']
      heap = @heap
      max = heap[0]
      heap[0] = heap[@['length'] - 1]
      @['length'] -= 1
      @heapify(0)
      max
    else
      null
  'push': (key) ->
    i = @['length']
    @['length'] += 1
    parent = @parent
    p = parent(i)
    heap = @heap
    f = @f
    while i > 0 and f(heap[p], key) > 0
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
    @heap = heap
    @['length'] = length
    @build()

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['MinHeap'] = MinHeap
