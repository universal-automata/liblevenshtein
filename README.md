# libLevenshtein

## A library for generating Finite State Transducers based on Levenshtein Automata.

For a quick demonstration, please visit the [Github Page, here](http://dylon.github.io/liblevenshtein/).

### Basic Usage:

To use the library on your website, reference the desired file from the
`<head/>` of your document, like so:

```html
<!DOCTYPE html>
<html>
  <head>
    <!-- stuff ... -->
    <script type="text/javascript"
      src="http://dylon.github.com/liblevenshtein/javascripts/2.0.0/levenshtein-transducer.min.js">
    </script>
    <!-- more stuff ... -->
  </head>
  <body>
    <!-- yet another fancy document ... -->
  </body>
</html>
```

Once the script loads, you should construct a transducer via the [Builder
Api](http://dylon.github.io/liblevenshtein/coffeescript/docs/builder.html):

```javascript
$(function ($) {
  "use strict";

  // Maximum number of spelling errors we will allow the spelling candidates to
  // have, with regard to the query term.
  var MAX_EDIT_DISTANCE = 2;

  var completion_list = getCompletionList(); // fictitious method

  var builder = new levenshtein.Builder()
    .dictionary(completion_list, false)  // generate spelling candidates from unsorted completion_list
    .algorithm("transposition")          // use Levenshtein distance extended with transposition
    .sort_candidates(true)               // sort the spelling candidates before returning them
    .case_insensitive_sort(true)         // ignore character-casing while sorting terms
    .include_distance(false)             // just return the ordered terms (drop the distances)
    .maximum_candidates(10);             // only want the top-10 candidates

  var transducer = builder.transducer();

  var $queryTerm = $('#query-term-input-field');
  $queryTerm.keyup(function (event) {
    var candidates, term = $.trim($queryTerm.val());

    if (term) {
      candidates = transducer.transduce(term, MAX_EDIT_DISTANCE);
      printAutoComplete(candidates); // print the list of completions
    } else {
      clearAutoComplete(); // user has cleared the search box
    }

    return true;
  });
});
```

This will give the user autocompletion hints (up to 10 of them) as he types in
the search box.

For more details, please see the [wiki](https://github.com/dylon/liblevenshtein/wiki).
