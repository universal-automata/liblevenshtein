# libLevenshtein

## A library for generating Finite State Transducers based on Levenshtein Automata.

For a quick demonstration, please visit the [Github Page, here](http://dylon.github.io/liblevenshtein/).

### Basic Usage:

Add the following `<script>` tag to the `<head>` section of your document:

```html
<script type="text/javascript"
	src="http://dylon.github.com/liblevenshtein/javascripts/v1.1.1/liblevenshtein.min.js">
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
manner.  Each result is a pair consisting of the transduced term and its
Levenshtein distance from the query term, as follows: `[term, distance]`

```javascript
var pair, term, distance, i = 0;
while ((pair = matches[i]) !== undefined) {
	term = pair[0]; distance = pair[1];
	// do something with `term` and `distance`
	i += 1;
}
```

If you would prefer to sort the results yourself, or do not care about order,
you may do the following:

```javascript
var transduce = levenshtein.transducer({
  dictionary: dictionary,
  algorithm: algorithm,
  sort_matches: false
});
```

The sorting options are as follows:

1. sort_matches := Whether to sort the transduced terms (boolean).
2. include_distance := Whether to include the Levenshtein distances with the
	 transduced terms (boolean).
3. case_insensitive := Whether to sort the results in a case-insensitive manner
	 (boolean).

Each option defaults to `true`.  You can get the original behavior of the
transducer by setting each option to `false` (where the original behavior was to
return the terms unsorted and excluding their distances).

### Building the library

#### CoffeeScript / JavaScript

You will need `npm` ([Node.js](http://nodejs.org/)) and `gradle` installed.
Be sure to install `coffee-script` via `sudo npm install -g coffee-script`.

Once that is installed, you should have the `cake` executable on your `$PATH`.
`cd` into the `coffeescript/` directory, and run `cake build` or `cake minify`
(if you want the minified, JavaScript library as well).  Once complete, you
should find the library under `lib/`.

### Background

Based largely on the works of [Stoyan Mihov](http://www.lml.bas.bg/~stoyan/),
[Klaus Schulz](http://www.klaus-schulze.com/), and Petar Nikolaev Mitankin, this
library generates Levenshtein transducers using nothing more than an input list
of dictionary terms. The referenced literature includes: 
"[Fast String Correction with Levenshtein-Automata](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.16.652 "Klaus Schulz and Stoyan Mihov (2002)")",
which defines the algorithm used to generate the Levenshtein automata,
"[Universal Levenshtein Automata. Building and Properties](http://www.fmi.uni-sofia.bg/fmi/logic/theses/mitankin-en.pdf "Petar Nikolaev Mitankin (2005)")",
which provided many mathematical proofs that helped me understand the algorithm
and supplied the recursive definitions upon which I based my distance functions,
and
"[Incremental Construction of Minimal Acyclic Finite-State Automata](http://dl.acm.org/citation.cfm?id=971842 "Jan Daciuk, Bruce W. Watson, Stoyan Mihov, and Richard E. Watson (2000)")",
that defined an algorithm for constructing Minimal Acyclic Finite-State
Automata in linear time (i.e. MA-FSA, also known as DAWGs: Directed Acyclic Word
Graphs) which I use to store the dictionary of terms.

Upon construction, the list of dictionary terms is indexed as an MA-FSA and a
transducer is initialized according to the maximum edit distance and algorithm
provided. When queried against, the states of the Levenshtein automaton
corresponding to the query term, maximum edit distance, and algorithm specified
are constructed on-demand (lazily) as the automaton is evaluated, as described
by the paper,
"[Fast String Correction with Levenshtein-Automata](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.16.652 "Klaus Schulz and Stoyan Mihov (2002)")".
The Levenshtein automaton is intersected with the dictionary MA-FSA, and every
string accepted by both automata is emitted in a list of correction candidates
for the query term.

In contrast to many other Levenshtein automata-based algorithms, the entire
Levenshtein automaton needn't be constructed prior to evaluation, and only those
states of the automaton which are actually required are derived, as needed,
thereby greatly improving the efficiency of the transducer in terms of both
space and time complexity.

The infamous blog post,
"[Damn Cool Algorithms: Levenshtein Automata](http://blog.notdot.net/2010/07/Damn-Cool-Algorithms-Levenshtein-Automata "Nick Johnson (2010)")",
provided me with a good starting point for this transducer, but the algorithm
proposed therein was too inefficient for my needs.  Yet, it did reference the
paper
"[Fast String Correction with Levenshtein-Automata](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.16.652 "Klaus Schulz and Stoyan Mihov (2002)")",
which I ultimately used as the basis of the Levenshtein automata.  The same
paper also serves as the basis of the Levenshtein automata used by the Apache
projects, Lucene and Solr ([Lucene's FuzzyQuery is 100 times faster in 4.0](http://blog.mikemccandless.com/2011/03/lucenes-fuzzyquery-is-100-times-faster.html)),
which itself is based on the project by Jean-Philippe Barrette-LaPierre, [Moman](https://sites.google.com/site/rrettesite/moman).

Steve Hanov pointed me to the paper, 
"[Incremental Construction of Minimal Acyclic Finite-State Automata](http://dl.acm.org/citation.cfm?id=971842 "Jan Daciuk, Bruce W. Watson, Stoyan Mihov, and Richard E. Watson (2000)")",
in his blog post entitled, "[Compressing dictionaries with a DAWG](http://stevehanov.ca/blog/index.php?id=115 "Steve Hanov (2011)")".
Another of Steve's blogs also made an impact on me, namely "[Fast and Easy Levenshtein distance using a Trie](http://stevehanov.ca/blog/index.php?id=114 "Steve Hanov (2011)")".

I've become heavily involved with the online movement regarding MOOCs (Massive
Open Online Classrooms), and the following courses taught me much regarding the
material within this library:

1. [Automata](https://class.coursera.org/automata "Jeffrey Ullman (Coursera)")
2. [Compilers](https://class.coursera.org/compilers "Alex Aiken (Coursera)")
3. [Natural Language Processing](https://class.coursera.org/nlp "Dan Jurafsky and Chris Manning (Coursera)")

Finally, I must credit the course which first introduced me to the field of
Information Retrieval, "Mathematical Applications in Search Engine Design",
taught by [Dr. Rao Li](http://www.usca.edu/math/~mathdept/rli/) at the
[University of South Carolina Aiken](http://web.usca.edu/). I highly recommend
that course if you are in the area.
