# Levshtein Automata

### Basic Usage:

Add the following script tag to the <code>&lt;head /&gt;</code> section of your
document:

```html
<script type="text/javascript"
	src="http://dylon.github.com/levenshtein_automata/javascripts/v1.0/liblevenshtein.min.js">
</script>
```

Then, within your JavaScript logic, you may use the library as follows:

```javascript
var dictionary = [ /* some list of words */ ];
var transduce = levenshtein.transducer({dictionary: dictionary, algorithm: "transposition"});

var query_term = "mispelled";
var max_edit_distance = 2;

var matches = transduce(query_term, max_edit_distance); // list of terms matching your query

var other_term = "oter";
var other_matches = transduce(other_term, max_edit_distance); // reuse the transducer
```
