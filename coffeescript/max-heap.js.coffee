class MaxHeap
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
    if l < @length and @f(heap[l], heap[i]) > 0
      largest = l
    else
      largest = i
    if r < @length and @f(heap[r], heap[largest]) > 0
      largest = r
    if largest isnt i
      tmp = heap[i]
      heap[i] = heap[largest]
      heap[largest] = tmp
      @heapify(largest)
    null
  build: () ->
    i = @length >> 1
    while i >= 0
      @heapify(i)
      i -= 1
    null
  increase_key: (i, key) ->
    f = @f
    heap = @heap
    c = f(key, heap[i])
    if c < 0
      throw new Error("Expected #{key} to be at least heap[#{i}] = #{heap[i]}")
    heap[i] = key
    parent = @parent
    p = parent(i)
    while i and f(heap[p], heap[i]) < 0
      tmp = heap[i]
      heap[i] = heap[p]
      heap[p] = tmp
      i = p
      p = parent(i)
    null
  sort: () ->
    @build()
    i = @length - 1
    heap = @heap
    while i >= 0
      tmp = heap[0]
      heap[0] = heap[i]
      heap[i] = tmp
      @length -= 1
      @heapify(0)
      i -= 1
    null
  pop: () ->
    if @length
      heap = @heap
      max = heap[0]
      heap[0] = heap[@length - 1]
      @length -= 1
      @heapify(0)
      max
  push: (key) ->
    i = @length
    @length += 1
    parent = @parent
    p = parent(i)
    heap = @heap
    f = @f
    while i > 0 and f(heap[p], key) < 0
      heap[i] = heap[p]
      i = p
      p = parent(i)
    heap[i] = key
    null
  constructor: (@f, @heap=[], @length=@heap.length) ->
    @build()

test = (A, f) ->
  B = new MaxHeap(f, A.slice())
  console.log((b while b = B.pop()))

  B = new MaxHeap(f)
  i = 0
  while i < A.length
    B.push(A[i])
    i += 1
  console.log((b while b = B.pop()))

  # Should be the reverse of the queue
  B = new MaxHeap(f, A.slice())
  B.sort()
  console.log(B.heap)

  # Note: This does funny things with a min-heap :)
  B = new MaxHeap(f, A.slice())
  B.increase_key(3, 5)
  console.log((b while b = B.pop()))

  null

# comparator
f = (a,b) -> a - b
#f = (a,b) -> b - a

test([1,2,3,4], f)
test([2,3,4,1], f)
test([3,4,1,2], f)
test([4,1,2,3], f)
test([2,1,3,4], f)
test([1,3,4,2], f)
test([3,4,2,1], f)
test([4,2,1,3], f)
test([2,3,1,4], f)
test([3,1,4,2], f)
test([1,4,2,3], f)
test([4,2,3,1], f)
test([1,3,2,4], f)
test([3,2,4,1], f)
test([2,4,1,3], f)
test([4,1,3,2], f)
test([1,2,4,3], f)
test([2,4,3,1], f)
test([4,3,1,2], f)
test([3,1,2,4], f)
test([4,3,2,1], f)
test([3,2,1,4], f)
test([2,1,4,3], f)
test([1,4,3,2], f)

