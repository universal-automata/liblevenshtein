{MinHeap} = require '../../src/collection/min-heap'
{permutations} = require '../../src/util/permutations'

c_num = (a,b) -> a - b #-> comparator for numbers

module.exports =
  'Instantiating a heap improperly should throw an error': (test) ->
    # No comparator
    test.throws -> new MinHeap()
    test.throws -> new MinHeap([1])
    # Heap length too large
    test.throws -> new MinHeap(c_num, [], 1)
    test.throws -> new MinHeap(c_num, [], -1)
    # Done
    test.done()
  'A min-heap on 0 elements should return null on *.peek() and *.pop()': (test) ->
    heap = new MinHeap(c_num)
    test.strictEqual(heap.peek(), null, 'expectected heap.peek() to return null')
    test.strictEqual(heap.pop(), null, 'expected heap.pop() to return null')
    test.done()
  'A min-heap with 1 element should return that element on *.peek() and *.pop(), and after *.pop() should return null.': (test) ->
    value = 42
    heap = new MinHeap(c_num, [value])
    test.strictEqual(heap.peek(), value, "expected heap.peek() to return #{value}")
    test.strictEqual(heap.pop(), value, "expected heap.pop() to return #{value}")
    test.strictEqual(heap.peek(), null, 'expected heap.peek() to return null')
    test.strictEqual(heap.pop(), null, 'expected heap.pop() to return null')
    test.done()
  'Every permutation of 0..6 should be dequeued in the same order': (test) ->
    test_heap = (heap) ->
      test.strictEqual(heap.length, order.length)
      i = 0
      while heap.peek() isnt null
        e = heap.peek()
        test.strictEqual(e, order[i], "Expected heap.peek() at index #{i} to return #{order[i]}, but received #{e} for permutation [#{permutation.join(',')}]")
        e = heap.pop()
        test.strictEqual(e, order[i], "Expected heap.pop() at index #{i} to return #{order[i]}, but received #{e} for permutation [#{permutation.join(',')}]")
        i += 1
      test.strictEqual(heap.length, 0)
    order = [0..6]
    for permutation in permutations(order)
      # Test heapified elements
      p = permutation.slice()
      heap = new MinHeap(c_num, p)
      test_heap(heap)
      # Test adding elements, one-by-one
      p = permutation.slice()
      heap = new MinHeap(c_num)
      heap.push(e) for e in p
      test_heap(heap)
      # Verify that sorting the heap returns elements in the reverse order
      p = permutation.slice()
      heap = new MinHeap(c_num, p)
      heap.sort()
      reverse_order = order.slice().reverse()
      test.deepEqual(heap.heap, reverse_order,
        "Expected the elements to be sorded in reverse-order ([#{reverse_order.join(',')}]), but received [#{heap.heap.join(',')}]")
    test.done()
