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
  STANDARD = 'standard'
  TRANSPOSITION = 'transposition'
  MERGE_AND_SPLIT = 'merge_and_split'
    
  distance = (algorithm) ->
    algorithm = STANDARD unless algorithm in [STANDARD, TRANSPOSITION, MERGE_AND_SPLIT]

    f = (u, t) ->
      if t < u.length
        u[t+1..]
      else
        ''

    # Source: http://www.fmi.uni-sofia.bg/fmi/logic/theses/mitankin-en.pdf
    switch algorithm

      # Calculates the Levenshtein distance between words v and w, using the
      # following primitive operations: deletion, insertion, and substitution.
      when STANDARD then do ->
        memoized_distance = {}
        distance = (v, w) ->
          key = v + '|' + w
          if (value = memoized_distance[key]) isnt `undefined`
            value
          else
            if v is ''
              memoized_distance[key] = w.length
            else if w is ''
              memoized_distance[key] = v.length
            else # v.length > 0 and w.length > 0
              a = v[0]; s = v[1..]
              b = w[0]; t = w[1..]

              # Discard identical characters
              while a is b and s.length > 0 and t.length > 0
                a = s[0]; v = s; s = s[1..]
                b = t[0]; w = t; t = t[1..]

              if a is b # s is '' or t is ''
                if s is ''
                  memoized_distance[key] = t.length # t.length >= 0
                else # t is ''
                  memoized_distance[key] = s.length # s.length > 0

              # p = 0 => (p <= q and p <= r) => min(p,q,r) = p
              else if (p = distance(s,w)) is 0
                memoized_distance[key] = 1  # 1 + min(p,q,r) = 1 + min(p = 0, q >= 0, r >= 0) = 1 + 0 = 1

              # (p > 0 and q = 0) => (q < p and q <= r) => min(p,q,r) = q
              else if (q = distance(v,t)) is 0
                memoized_distance[key] = 1  # 1 + min(p,q,r) = 1 + min(p > 0, q = 0, r >= 0) = 1 + 0 = 1

              # (p > 0 and q > 0 and r = 0) => (r < p and r < q) => min(p,q,r) = r
              else if (r = distance(s,t)) is 0
                memoized_distance[key] = 1  # 1 + min(p,q,r) = 1 + min(p > 0, q > 0, r = 0) = 1 + 0 = 1

              # p > 0, q > 0, and r > 0
              else
                memoized_distance[key] = 1 + Math.min(p,q,r)

      # Calculates the Levenshtein distance between words v and w, using the
      # following primitive operations: deletion, insertion, substitution, and
      # transposition.
      when TRANSPOSITION then do ->
        memoized_distance = {}
        distance = (v, w) ->
          key = v + '|' + w
          if (value = memoized_distance[key]) isnt `undefined`
            value
          else
            if v is ''
              memoized_distance[key] = w.length
            else if w is ''
              memoized_distance[key] = v.length
            else # v.length > 0 and w.length > 0
              a = v[0]; x = v[1..]
              b = w[0]; y = w[1..]

              # Discard identical characters
              while a is b and x.length > 0 and y.length > 0
                a = x[0]; v = x; x = x[1..]
                b = y[0]; w = y; y = y[1..]

              if a is b # x is '' or y is ''
                memoized_distance[key] = x.length || y.length

              # p = 0 => (p <= q and p <= r) => min(p,q,r) = p
              else if (p = distance(x,w)) is 0
                memoized_distance[key] = 1  # 1 + min(p,q,r) = 1 + min(p = 0, q >= 0, r >= 0) = 1 + 0 = 1

              # (p > 0 and q = 0) => (q < p and q <= r) => min(p,q,r) = q
              else if (q = distance(v,y)) is 0
                memoized_distance[key] = 1  # 1 + min(p,q,r) = 1 + min(p > 0, q = 0, r >= 0) = 1 + 0 = 1

              # (p > 0 and q > 0 and r = 0) => (r < p and r < q) => min(p,q,r) = r
              else if (r = distance(x,y)) is 0
                memoized_distance[key] = 1  # 1 + min(p,q,r) = 1 + min(p > 0, q > 0, r = 0) = 1 + 0 = 1

              # p > 0, q > 0, and r > 0
              else
                a1 = x[0]  # prefix character of x
                b1 = y[0]  # prefix character of y
                if a is b1 and a1 is b
                  if (s = distance(f(v,1), f(w,1))) is 0
                    memoized_distance[key] = 1
                  else
                    memoized_distance[key] = 1 + Math.min(p,q,r,s)
                else
                  memoized_distance[key] = 1 + Math.min(p,q,r)

      # Calculates the Levenshtein distance between words v and w, using the
      # following primitive operations: deletion, insertion, substitution,
      # merge, and split.
      when MERGE_AND_SPLIT then do ->
        memoized_distance = {}
        distance = (v, w) ->
          key = v + '|' + w
          if (value = memoized_distance[key]) isnt `undefined`
            value
          else
            if v is ''
              memoized_distance[key] = w.length
            else if w is ''
              memoized_distance[key] = v.length
            else # v.length > 0 and w.length > 0
              a = v[0]; x = v[1..]
              b = w[0]; y = w[1..]

              # Discard identical characters
              while a is b and x.length > 0 and y.length > 0
                a = x[0]; v = x; x = x[1..]
                b = y[0]; w = y; y = y[1..]

              if a is b
                memoized_distance[key] = x.length || y.length
              else if (p = distance(x,w)) is 0
                memoized_distance[key] = 1
              else if (q = distance(v,y)) is 0
                memoized_distance[key] = 1
              else if (r = distance(x,y)) is 0
                memoized_distance[key] = 1
              else if (s = if w.length > 1 then distance(x, f(w,1)) else Infinity) is 0
                memoized_distance[key] = 1
              else if (t = if v.length > 1 then distance(f(v,1), y) else Infinity) is 0
                memoized_distance[key] = 1
              else
                memoized_distance[key] = 1 + Math.min(p,q,r,s,t)

  if typeof exports isnt 'undefined'
    exports.distance = distance
  else if typeof levenshtein isnt 'undefined'
    levenshtein.distance = distance
  else
    throw new Error('Cannot find either the "levenshtein" or "exports" variable')

