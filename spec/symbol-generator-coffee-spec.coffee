{getGrammar, checkSymbols} = require './spec-utils'

describe 'SymbolIndex', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-coffee-script')

  describe 'coffeeScript', ->
    grammar = null
    beforeEach ->
      grammar = getGrammar 'coffee'

    it 'should find require variables', ->
      checkSymbols "foo = require 'fs'", grammar, foo: [ [0, 0] ]

    it 'should find deconstructed require variables', ->
      checkSymbols "{EventEmitter} = require 'events'", grammar, EventEmitter: [ [0, 1] ]

    it 'should find simple variable assignment', ->
      checkSymbols "ab = 1", grammar, ab: [ [0, 0] ]

    it 'should find things on additional lines', ->
      checkSymbols "0\na = 1", grammar, a: [ [1, 0] ]

    it 'should find simple variable assignment and referred value', ->
      checkSymbols "a = b", grammar, a: [ [0, 0] ], b: [ [0, 4] ]

    it 'should find function definitions', ->
      checkSymbols "a = ->", grammar, a: [ [0, 0] ]

    it 'should find function parameters', ->
      checkSymbols "a = (b, c) ->", grammar, a: [ [0, 0] ], b: [ [0, 5] ], c: [ [0, 8] ]

    it 'should find parameters in called function', ->
      checkSymbols "a(b, c)", grammar, a: [ [0, 0] ], b: [ [0, 2] ], c: [ [0, 5] ]

    it 'should find parameters in called function w/o parens', ->
      checkSymbols "a b, c", grammar, a: [ [0, 0] ], b: [ [0, 2] ], c: [ [0, 5] ]

    it 'should find variables in function bodies', ->
      checkSymbols "a = -> c=1; return c", grammar, a: [ [0, 0] ], c: [ [0, 7], [0, 19] ]

    it 'should find variables in multi-line function bodies', ->
      checkSymbols "a = ->\n  c=1\n  return c", grammar, a: [ [0, 0] ], c: [ [1, 2], [2, 9] ]

    it 'should ignore comments', ->
      checkSymbols 'a = 1 # b = c', grammar, a: [ [0, 0] ]

    it 'should ignore block comments', ->
      checkSymbols '###\nb\n###', grammar, {}

    it 'should ignore booleans', ->
      checkSymbols 'a = true\nb = false', grammar, a: [ [0, 0] ], b: [ [1, 0] ]

    xit 'should find variables in interpolated strings', ->
      # Not yet working
      checkSymbols '"find #{foo} here"', grammar, foo: [ [0, 8] ]
