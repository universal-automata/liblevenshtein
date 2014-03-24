fs = require 'fs'

{levenshtein: {distance}} = require '../../src/levenshtein/distance'

lorem_ipsum = do ->
  path = "#{__dirname}/../../../shared/resources/lorem-ipsum-terms.txt"
  lorem_ipsum = fs.readFileSync(path, 'utf8').split('\n')
  if lorem_ipsum[lorem_ipsum.length - 1] is ''
    lorem_ipsum.pop() #-> drop the empty string
  lorem_ipsum

axioms =
  equal_self_similarity: (test) ->
    d = @distance
    i = 0
    while i < lorem_ipsum.length
      a = lorem_ipsum[i]
      x = d(a,a)
      j = 0
      while j < lorem_ipsum.length
        b = lorem_ipsum[j]
        y = d(b,b)
        if x isnt y
          test.ok false, "Expected d(#{a},#{a}) = d(#{b},#{b})"
        j += 1
      i += 1
    test.done()
  minimality: (test) ->
    d = @distance
    i = 0
    while i < lorem_ipsum.length
      a = lorem_ipsum[i]
      x = d(a,a)
      j = 0
      while j < i
        b = lorem_ipsum[j]
        y = d(a,b)
        z = d(b,a)
        unless y > x
          test.ok false, "Expected d(#{a},#{b}) > d(#{a},#{a})"
        unless z > x
          test.ok false, "Expected d(#{b},#{a}) > d(#{a},#{a})"
        j += 1
      j = i + 1
      while j < lorem_ipsum.length
        b = lorem_ipsum[j]
        y = d(a,b)
        z = d(b,a)
        unless y > x
          test.ok false, "Expected d(#{a},#{b}) > d(#{a},#{a})"
        unless z > x
          test.ok false, "Expected d(#{b},#{a}) > d(#{a},#{a})"
        j += 1
      i += 1
    test.done()
  symmetry: (test) ->
    d = @distance
    i = 0
    while i < lorem_ipsum.length
      a = lorem_ipsum[i]
      j = 0
      while j < lorem_ipsum.length
        b = lorem_ipsum[j]
        x = d(a,b)
        y = d(b,a)
        if x isnt y
          test.ok false, "Expected d(#{a},#{b}) = d(#{b},#{a})"
        j += 1
      i += 1
    test.done()
  triangle_inequality: (test) ->
    d = @distance
    i = 0
    while i < lorem_ipsum.length
      a = lorem_ipsum[i]
      j = 0
      while j < lorem_ipsum.length
        b = lorem_ipsum[j]
        x = d(a,b)
        k = 0
        while k < lorem_ipsum.length
          c = lorem_ipsum[k]
          y = d(a,c)
          z = d(b,c)
          unless x + y >= z
            test.ok false, "Expected d(#{a},#{b}) + d(#{a},#{c} >= d(#{b},#{c}))"
          unless x + z >= y
            test.ok false, "Expected d(#{a},#{b}) + d(#{b},#{c} >= d(#{a},#{c}))"
          unless y + z >= x
            test.ok false, "Expected d(#{a},#{c}) + d(#{b},#{c} >= d(#{a},#{b}))"
          k += 1
        j += 1
      i += 1
    test.done()

operations = (algorithm, transposition=2, merge=2, split=2) ->
  tests =
    setUp: (callback) ->
      @distance = distance(algorithm)
      callback()
    'The distance should conform to Equal Self-Similarity': axioms.equal_self_similarity
    'The distance should conform to Minimality': axioms.minimality
    'The distance should conform to Symmetry': axioms.symmetry
    'The distance should conform to the Triangle Inequality': axioms.triangle_inequality
    'The distance between a term and itself should be 0': (test) ->
      test.strictEqual @distance('foo', 'foo'), 0
      test.done()
    'An insertion should incur a penalty of 1 unit': (test) ->
      test.strictEqual @distance('foo', 'food'), 1
      test.strictEqual @distance('foo', 'fodo'), 1
      test.strictEqual @distance('foo', 'fdoo'), 1
      test.strictEqual @distance('foo', 'dfoo'), 1
      test.done()
    'A deletion should incur a penalty of 1 unit': (test) ->
      test.strictEqual @distance('foo', 'oo'), 1
      test.strictEqual @distance('foo', 'fo'), 1
      test.done()
    'A substitution should incur a penalty of 1 unit': (test) ->
      test.strictEqual @distance('foo', 'boo'), 1
      test.strictEqual @distance('foo', 'fbo'), 1
      test.strictEqual @distance('foo', 'fob'), 1
      test.done()
  tests["A transposition should incur a penalty of #{transposition} unit(s)"] =
    (test) ->
      test.strictEqual @distance('foo', 'ofo'), transposition
      test.done()
  tests["A merge should incur a penalty of #{merge} unit(s)"] =
    (test) ->
      test.strictEqual @distance('clog', 'dog'), merge
      test.done()
  tests["A split should incur a penalty of #{split} unit(s)"] =
    (test) ->
      test.strictEqual @distance('dog', 'clog'), split
      test.done()
  tests

module.exports =
  'Levenshtein Distance': operations('standard')
  'Levenshtein Distance Extended with Transposition': operations('transposition', 1)
  'Levenshtein Distance Extended with Merge and Split': operations('merge_and_split', 2, 1, 1)
