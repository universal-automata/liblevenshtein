global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['operations'] =
  insertion: (term, alphabet, random) ->
    # Select a random character to insert
    c = alphabet[(random() * alphabet.length) >> 0]
    # Select a random index at which to insert the character
    i = (random() * (1 + term.length)) >> 0
    # Insert the charater at the random index
    term.slice(0,i) + c + term.slice(1 + i)

  deletion: (term, alphabet, random) ->
    # Select a random index for deletion
    i = (random() * term.length) >> 0
    # Delete the character at the random index
    term.slice(0,i) + term.slice(i+1)

  substitution: (term, alphabet, random) ->
    # Select a random character to substitute
    c = alphabet[(random() * alphabet.length) >> 0]
    # Select a random index for substitution
    i = (random() * term.length) >> 0
    # Substitute the character at the random index
    term.slice(0,i) + c + term.slice(i+1)

  transposition: (term, alphabet, random) ->
    if term.length > 1
      # Select a random index to transpose
      i = (random() * (term.length - 1)) >> 0
      # Transpose the characters at i and i+1
      term.slice(0,i) + term[i+1] + term[i] + term.slice(i+2)
    else
      term

  merge: (term, alphabet, random) ->
    if term.length > 1
      # Select a random character to merge-in
      c = alphabet[(random() * alphabet.length) >> 0]
      # Select a random index to merge
      i = (random() * (term.length - 1)) >> 0
      # Merge the characters at i and i+1
      term.slice(0,i) + c + term.slice(i+2)
    else
      term

  split: (term, alphabet, random) ->
    # Select two random characters to split-out
    c = alphabet[(random() * alphabet.length) >> 0]
    d = alphabet[(random() * alphabet.length) >> 0]
    # Select a random index to split
    i = (random() * (term.length - 1)) >> 0
    # Split the character at i
    term.slice(0,i) + c + d + term.slice(i+1)
