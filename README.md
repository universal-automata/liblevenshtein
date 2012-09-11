# Levshtein Automata

### Basic Usage:

Add the following `<script>` tag to the `<head>` section of your document:

```html
<script type="text/javascript"
	src="http://dylon.github.com/levenshtein_automata/javascripts/v1.0/liblevenshtein.min.js">
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

If you would like to rank the transduced terms according to their distance from
the query term, you may do the following (using the same variables as above):

```javascript
var distance = levenshtein.distance(algorithm); // accepts the same algorithms as the transducer

// Sort the matches in ascending order according to distance, first, then
// lexicographically (for dictionary terms having the same distance from the
// query term).
matches.sort(function (lhs, rhs) {
	return distance(query_term, lhs) - distance(query_term, rhs) || lhs.localeCompare(rhs);
});
```
