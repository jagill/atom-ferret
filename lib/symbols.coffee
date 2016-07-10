{Range, Point} = require 'atom'
{RangeTrie} = require './range-trie'


## ------- HELPERS

### Unused, but good reference for the future
VARIABLE_REGEXPS = [
  /^variable\.assignment/,
  /^variable\.parameter/,
  /^entity\.name\.function/,
  /^variable\.parameter\.function/,
  /^meta\.variable\.assignment/,
]
###

BLACKLIST_REGEXP = /// ^ (
  ?: punctuation
   | keyword
   | string
   | comment
   | constant  # Ruby has constant.other.symbol; should keep this?
   | meta\.brace
   | meta\.delimiter
   | storage\.type
   | storage\.modifier
   | support\.function
) ///

wordRegexp = /\w+/g

# Return an array (possibly empty) of symbols in the token.
# TODO: When possible add definition/assignment info.
findSymbolsInToken = (token) ->
  return [] unless token? and shouldParse token.scopes
  matches = []
  while result = wordRegexp.exec(token.value)
    matches.push name: result[0], offsetMod: result.index
  return matches

shouldParse = (scopes) ->
  for scope in scopes
    return false if BLACKLIST_REGEXP.test(scope)
    # for regexp in BLACKLIST_REGEXPS
    #   return false if regexp.test(scope)

  return true

class SymbolIndex
  constructor: ->
    @index = new Map() # path -> RangeTrie

  _assertParsed: (filepath) ->
    if not filepath of @index
      throw new Error("Trying to access symbols for #{filepath}, but they haven't been generated yet.")

  # Parses the symbols in text according to grammar, storing the results
  # under filepath
  parse: (editor, lineOffset=0) ->
    tick = Date.now()

    filepath = editor.getPath()
    if filepath not of @index
      @index[filepath] = new RangeTrie()

    lines = editor.getGrammar().tokenizeLines(editor.getText())
    for tokens, linenum in lines
      colOffset = 0
      for token in tokens
        for symbol in findSymbolsInToken(token)
          name = symbol.name
          start = new Point(linenum + lineOffset, colOffset + symbol.offsetMod)
          @index[filepath].add(name, start)
        colOffset +=  token.value.length

    elapsed = Date.now() - tick
    if elapsed > 100
      console.log "Parsing symbols in #{filepath} took #{elapsed} ms"

  # Return a list of positions for the symbol in filepath.
  findPositions: (filepath, symbol) ->
    @_assertParsed filepath
    return @index[filepath].find(symbol)

  # Return a map of symbol:positions for all symbols in filepath
  findAllPositions: (filepath) ->
    @_assertParsed filepath
    return @index[filepath].findAll()

  # Return a map of symbol:positions for symbols in filepath with prefix.
  findPositionsForPrefix: (filepath, prefix) ->
    @_assertParsed filepath
    return @index[filepath].findPrefix(prefix)

exports.SymbolIndex = SymbolIndex
