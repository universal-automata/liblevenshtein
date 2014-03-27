###
Takes a list of arity-1, mutation functions and their corresponding
probabilities, the maximum number of mutations to generate, an arity-0 function
for generating random numbers between 0 and 1, and a target to apply mutations
to, and returns the target, transformed according to a (pseudo-)random series of
mutations.
###
mutate = (mutations, max_mutations, random, target) ->
  p_sum = 0
  p_sum += p for [p, mutation] in mutations

  i = -1
  mutations[i][0] /= p_sum while (++i) < mutations.length

  num_mutations = random() * max_mutations
  i = -1; while (++i) < num_mutations
    rand = random()
    p_sum = 0
    j = 0
    p_sum += mutations[j++][0] while mutations[j][0] + p_sum < rand
    mutation = mutations[j][1]
    target = mutation(target)

  target

global =
  if typeof exports is 'object'
    exports
  else if typeof window is 'object'
    window
  else
    this

global['levenshtein'] ||= {}
global['levenshtein']['mutate'] = mutate
