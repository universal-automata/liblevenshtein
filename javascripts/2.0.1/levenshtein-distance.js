/**
@license
The MIT License (MIT)

Copyright (c) 2014 Dylon Edwards

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/
// Generated by CoffeeScript 1.7.1
(function() {
  var distance, global;

  distance = function(algorithm) {
    var f;
    if (algorithm !== 'standard' && algorithm !== 'transposition' && algorithm !== 'merge_and_split') {
      algorithm = 'standard';
    }
    f = function(u, t) {
      if (t < u.length) {
        return u.slice(t + 1);
      } else {
        return '';
      }
    };
    switch (algorithm) {
      case 'standard':
        return (function(distance) {
          var memoized_distance;
          memoized_distance = {};
          return distance = function(v, w) {
            var a, b, key, min, p, s, t, value;
            key = v + '\0' + w;
            if ((value = memoized_distance[key]) !== undefined) {
              return value;
            } else {
              if (v === '') {
                return memoized_distance[key] = w.length;
              } else if (w === '') {
                return memoized_distance[key] = v.length;
              } else {
                a = v[0];
                s = v.slice(1);
                b = w[0];
                t = w.slice(1);
                while (a === b && s.length > 0 && t.length > 0) {
                  a = s[0];
                  v = s;
                  s = s.slice(1);
                  b = t[0];
                  w = t;
                  t = t.slice(1);
                }
                if (a === b) {
                  return memoized_distance[key] = s.length || t.length;
                }
                if ((p = distance(s, w)) === 0) {
                  return memoized_distance[key] = 1;
                }
                min = p;
                if ((p = distance(v, t)) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                if ((p = distance(s, t)) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                return memoized_distance[key] = 1 + min;
              }
            }
          };
        })(distance);
      case 'transposition':
        return (function(distance) {
          var memoized_distance;
          memoized_distance = {};
          return distance = function(v, w) {
            var a, a1, b, b1, key, min, p, value, x, y;
            key = v + '\0' + w;
            if ((value = memoized_distance[key]) !== undefined) {
              return value;
            } else {
              if (v === '') {
                return memoized_distance[key] = w.length;
              } else if (w === '') {
                return memoized_distance[key] = v.length;
              } else {
                a = v[0];
                x = v.slice(1);
                b = w[0];
                y = w.slice(1);
                while (a === b && x.length > 0 && y.length > 0) {
                  a = x[0];
                  v = x;
                  x = x.slice(1);
                  b = y[0];
                  w = y;
                  y = y.slice(1);
                }
                if (a === b) {
                  return memoized_distance[key] = x.length || y.length;
                }
                if ((p = distance(x, w)) === 0) {
                  return memoized_distance[key] = 1;
                }
                min = p;
                if ((p = distance(v, y)) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                if ((p = distance(x, y)) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                a1 = x[0];
                b1 = y[0];
                if (a === b1 && a1 === b) {
                  if ((p = distance(f(v, 1), f(w, 1))) === 0) {
                    return memoized_distance[key] = 1;
                  }
                  if (p < min) {
                    min = p;
                  }
                }
                return memoized_distance[key] = 1 + min;
              }
            }
          };
        })(distance);
      case 'merge_and_split':
        return (function(distance) {
          var memoized_distance;
          memoized_distance = {};
          return distance = function(v, w) {
            var a, b, key, min, p, value, x, y;
            key = v + '\0' + w;
            if ((value = memoized_distance[key]) !== undefined) {
              return value;
            } else {
              if (v === '') {
                return memoized_distance[key] = w.length;
              } else if (w === '') {
                return memoized_distance[key] = v.length;
              } else {
                a = v[0];
                x = v.slice(1);
                b = w[0];
                y = w.slice(1);
                while (a === b && x.length > 0 && y.length > 0) {
                  a = x[0];
                  v = x;
                  x = x.slice(1);
                  b = y[0];
                  w = y;
                  y = y.slice(1);
                }
                if (a === b) {
                  return memoized_distance[key] = x.length || y.length;
                }
                if ((p = distance(x, w)) === 0) {
                  return memoized_distance[key] = 1;
                }
                min = p;
                if ((p = distance(v, y)) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                if ((p = distance(x, y)) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                if ((p = w.length > 1 ? distance(x, f(w, 1)) : Infinity) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                if ((p = v.length > 1 ? distance(f(v, 1), y) : Infinity) === 0) {
                  return memoized_distance[key] = 1;
                }
                if (p < min) {
                  min = p;
                }
                return memoized_distance[key] = 1 + min;
              }
            }
          };
        })(distance);
    }
  };

  global = typeof exports === 'object' ? exports : typeof window === 'object' ? window : this;

  global['levenshtein'] || (global['levenshtein'] = {});

  global['levenshtein']['distance'] = distance;

}).call(this);

