{getGrammar, checkSymbols} = require './spec-utils'
{Point} = require 'atom'

describe 'SymbolIndex', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

  describe 'JavaScript', ->
    grammar = null
    beforeEach ->
      grammar = getGrammar 'js'

    it 'should find simple variable assignment', ->
      checkSymbols "ab = 1;", grammar, ab: [ [0, 0] ]

    it 'should find simple variable declaration', ->
      checkSymbols "var a = 1;", grammar, a: [ [0, 4] ]

    it 'should find require variables', ->
      checkSymbols "foo = require('fs')", grammar, foo: [ [0, 0] ]

    it 'should find things on additional lines', ->
      checkSymbols "0\na = 1", grammar, a: [ [1, 0] ]

    it 'should find simple variable assignment and referred value', ->
      checkSymbols "a = b", grammar, a: [ [0, 0] ], b: [ [0, 4] ]

    it 'should find function definitions', ->
      checkSymbols "function a() {}", grammar, a: [ [0, 9] ]

    it 'should find function assignments', ->
      checkSymbols "a = function () {}", grammar, a: [ [0, 0] ]

    it 'should find function parameters', ->
      checkSymbols "a = function (b, c) {}", grammar, a: [ [0, 0] ], b: [ [0, 14] ], c: [ [0, 17] ]

    it 'should find parameters in called function', ->
      checkSymbols "a(b, c)", grammar, a: [ [0, 0] ], b: [ [0, 2] ], c: [ [0, 5] ]

    it 'should find variables in function bodies', ->
      checkSymbols "a = function() {c=1; return c;}", grammar, a: [ [0, 0] ], c: [ [0, 16], [0, 28] ]

    it 'should find variables in multi-line function bodies', ->
      checkSymbols "a = function() {\n  c=1;\n  return c;\n}", grammar, a: [ [0, 0] ], c: [ [1, 2], [2, 9] ]

    it 'should ignore comments', ->
      checkSymbols 'a = 1 // b = c', grammar, a: [ [0, 0] ]

    it 'should ignore block comments', ->
      checkSymbols '/*\nb\n*/', grammar, {}

    it 'should ignore booleans', ->
      checkSymbols 'a = true\nb = false', grammar, a: [ [0, 0] ], b: [ [1, 0] ]

    it 'should handle built in object names like hasOwnProperty', ->
      checkSymbols 'var __hasProp = {}.hasOwnProperty;', grammar, __hasProp: [ [0, 4] ], hasOwnProperty: [ [0, 19] ]

    # XXX TODO: Re-enable; it looks like jasmine is handling 'toEqual' strangely.
    xit 'should handle built in object names like constructor', ->
      checkSymbols 'var constructor = function () {}', grammar, constructor: [ {row: 0, column: 4} ]
