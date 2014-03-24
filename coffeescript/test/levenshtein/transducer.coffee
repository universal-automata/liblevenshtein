fs = require 'fs'

{levenshtein: {distance}} = require '../../src/levenshtein/distance'
{levenshtein: {transducer}} = require '../../src/levenshtein/transducer'

lorem_ipsum = do ->
  path = "#{__dirname}/../../../shared/resources/lorem-ipsum-terms.txt"
  lorem_ipsum = fs.readFileSync(path, 'utf8').split('\n')
  if lorem_ipsum[lorem_ipsum.length - 1] is ''
    lorem_ipsum.pop() #-> drop the empty string
  lorem_ipsum

