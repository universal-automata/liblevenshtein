# Levshtein Automata

### Basic Usage:

Add the following `<script>` tag to the `<head>` section of your document:

```html
<script type="text/javascript"
	src="http://dylon.github.com/levenshtein_automata/javascripts/v1.1/liblevenshtein.min.js">
</script>
```

Then, within your JavaScript logic, you may use the library as follows:

```javascript
var algorithm = "transposition"; // "standard", "transposition", or "merge_and_split"

var dictionary = [ /* some list of words */ ];
var transduce = levenshtein.transducer({dictionary: dictionary, algorithm: algorithm});

var query_term = "mispelled";
var max_edit_distance = 2;

var matches = transduce(query_term, max_edit_distance); // list of terms matching your query

var other_term = "oter";
var other_matches = transduce(other_term, max_edit_distance); // reuse the transducer
```

The default behavior of the transducer is to sort the results, ascendingly, in
the following fashion: first according to the transduced terms' Levenshtein
distances from the query term, then lexicographically, in a case insensitive
manner.  Each result is a pair consisting of the transuced term and its
Levenshtein distance from the query term, as follows: `[term, distance]`

If you would prefer to sort the results yourself, or do not care about order,
you may do the following:

```javascript
var transduce = levenshtein.transducer({
  dictionary: dictionary,
  algorithm: algorithm,
  sort_results: false
});
```

The sorting options are as following:
1. sort_matches := Whether to sort the transduced terms.
2. include_distance := Whether to include the Levenshtein distances with the transduced terms.
3. case_insensitive := Whether to sort the results in a case-insensitive manner.

Each option defaults to `true`.  You can get the original behavior of the
transducer by setting each option to false (where the original behavior was to
return the terms unsorted and excluding their distances).
