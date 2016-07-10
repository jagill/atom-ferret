{getGrammar, checkSymbols} = require './spec-utils'

describe 'SymbolIndex', ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-python')

  describe 'python', ->
    grammar = null
    beforeEach ->
      grammar = getGrammar 'py'

    it 'should find import variables', ->
      checkSymbols "import foo", grammar, foo: [ [0, 7] ]

    it 'should find import-as variables', ->
      checkSymbols "import foo as bar", grammar, foo: [ [0, 7] ], bar: [ [0, 14] ]

    it 'should find import-from variables', ->
      checkSymbols "from foo import bar", grammar, foo: [ [0, 5] ], bar: [ [0, 16] ]

    it 'should find simple variable assignment', ->
      checkSymbols "ab = 1", grammar, ab: [ [0, 0] ]

    it 'should find global variable declaration', ->
      checkSymbols "global a", grammar, a: [ [0, 7] ]

    it 'should find things on additional lines', ->
      checkSymbols "0\na = 1", grammar, a: [ [1, 0] ]

    it 'should find simple variable assignment and referred value', ->
      checkSymbols "a = b", grammar, a: [ [0, 0] ], b: [ [0, 4] ]

    it 'should find function definitions', ->
      checkSymbols "def a():", grammar, a: [ [0, 4] ]

    it 'should find function parameters', ->
      checkSymbols "def a(b, c):", grammar, a: [ [0, 4] ], b: [ [0, 6] ], c: [ [0, 9] ]

    it 'should find parameters in called function', ->
      checkSymbols "a(b, c)", grammar, a: [ [0, 0] ], b: [ [0, 2] ], c: [ [0, 5] ]

    it 'should find variables in multi-line function bodies', ->
      checkSymbols "a = ->\n  c=1\n  return c", grammar, a: [ [0, 0] ], c: [ [1, 2], [2, 9] ]

    it 'should ignore comments', ->
      checkSymbols 'a = 1 # b = c', grammar, a: [ [0, 0] ]

    it 'should ignore booleans', ->
      checkSymbols 'a = True\nb = False', grammar, a: [ [0, 0] ], b: [ [1, 0] ]
