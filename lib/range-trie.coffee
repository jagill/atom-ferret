utils = require './utils'

###*
A data structure to contain, for a given file, symbols and their positions.

Operations: (N is number of symbols, M number of matched symbols, P number of positions per symbole)
  add(symbol, position): Add symbol at position. O(ln N).  Must add in position order.
  findAll(symbol): Return positions of symbol. O(ln N)
  findAllPrefix(prefix): Return map {symbol: positions} for all symbols with
    prefix.  O(ln N + M)

This is inspired by the 3-way Trie.
###

###*
Trie node, containing a character, positions (if the trie is a complete symbol),
and child nodes.
###
class Node
  constructor: ->
    @positions = []
    @children = {}  # next letter -> node

exports.RangeTrie = class RangeTrie
  constructor: ->
    @root = new Node()

  _add: (node, symbol, position, charIndex) ->
    unless node
      node = new Node()

    if charIndex == symbol.length
      utils.insertOrdered(position, node.positions)
    else
      # Else we still have characters to traverse
      ch = symbol[charIndex++]
      node.children[ch] = @_add(node.children[ch], symbol, position, charIndex)

    return node

  # Collect (in symbolMap) all the points for symbols in this subtree
  # NB: Modifies symbolMap
  _collect: (node, prefix, symbolMap) ->
    return unless node

    if node.positions.length
      symbolMap[prefix] = node.positions

    for ch, child of node.children
      @_collect(child, prefix + ch, symbolMap)

  add: (symbol, position) ->
    return unless symbol?.length
    @_add(@root, symbol, position, 0)

  # Return an ordered list of positions for symbol, or an empty list
  # if there are no positions.
  find: (symbol) ->
    node = @root
    charIndex = 0
    while node and charIndex < symbol.length
      ch = symbol[charIndex++]
      node = node.children[ch]

    return if node then node.positions else []

  findPrefix: (prefix) ->
    node = @root
    charIndex = 0
    while node and charIndex < prefix.length
      ch = prefix[charIndex++]
      node = node.children[ch]

    # console.log "Searching prefix node: #{JSON.stringify(node)}"
    symbolMap = {}
    @_collect(node, prefix, symbolMap)

    return symbolMap

  findAll: ->
    return @findPrefix ''
