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

            # s.length is 0 or t.length is 0
            return memoized_distance[key] = s.length || t.length if a is b

            return memoized_distance[key] = 1 if (p = distance(s,w)) is 0
            min = p

            return memoized_distance[key] = 1 if (p = distance(v,t)) is 0
            min = p if p < min

            return memoized_distance[key] = 1 if (p = distance(s,t)) is 0
            min = p if p < min

            return memoized_distance[key] = 1 + min

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

            # x.length is 0 or y.length is 0
            return memoized_distance[key] = x.length || y.length if a is b

            return memoized_distance[key] = 1 if (p = distance(x,w)) is 0
            min = p

            return memoized_distance[key] = 1 if (p = distance(v,y)) is 0
            min = p if p < min

            return memoized_distance[key] = 1 if (p = distance(x,y)) is 0
            min = p if p < min

            a1 = x[0]  # prefix character of x
            b1 = y[0]  # prefix character of y
            if a is b1 and a1 is b
              return memoized_distance[key] = 1 if (p = distance(f(v,1), f(w,1))) is 0
              min = p if p < min

            return memoized_distance[key] = 1 + min

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

            # x.length is 0 or y.length is 0
            return memoized_distance[key] = x.length || y.length if a is b

            return memoized_distance[key] = 1 if (p = distance(x,w)) is 0
            min = p

            return memoized_distance[key] = 1 if (p = distance(v,y)) is 0
            min = p if p < min

            return memoized_distance[key] = 1 if (p = distance(x,y)) is 0
            min = p if p < min

            return memoized_distance[key] = 1 if (p = if w.length > 1 then distance(x, f(w,1)) else Infinity) is 0
            min = p if p < min

            return memoized_distance[key] = 1 if (p = if v.length > 1 then distance(f(v,1), y) else Infinity) is 0
            min = p if p < min

            return memoized_distance[key] = 1 + min

levenshtein['distance'] = distance

