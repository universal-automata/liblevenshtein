yaml = require 'js-yaml'
fs = require 'fs'

{levenshtein: {Dawg}} = require '../../src/collection/dawg'

programming_languages = do ->
  path = "#{__dirname}/../../../shared/resources/programming-languages.yaml"
  yaml.safeLoad fs.readFileSync(path, 'utf8')

module.exports =
  'Instantiating a DAWG without a list should throw an error': (test) ->
    test.throws -> new Dawg()
    test.done()
  'An empty DAWG should not accept anything': (test) ->
    dawg = new Dawg([])
    test.strictEqual(dawg.accepts(''), false)
    test.strictEqual(dawg.accepts('foobar'), false)
    test.done()
  'A DAWG should accept all and only its complete terms': (test) ->
    dawg = new Dawg(programming_languages)
    test.strictEqual dawg.accepts(''), false, 'Expected dawg to reject empty string'
    test.strictEqual dawg.accepts('foobarbaz'), false,
      'Expected dawg to reject "foobarbaz", since it is not a programming language'
    for lang in programming_languages
      test.ok dawg.accepts(lang), "Expected dawg to accept #{lang}"
    test.done()
