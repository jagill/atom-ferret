utils = require './utils'

###*
A data structure to contain, for a given file, markers surrounding each symbol.

Operations: (N is number of symbols, M number of matched symbols, P number of markers per symbole)
  add(symbol, position): Add marker for symbol at position. O(ln N).
  findAll(symbol): Return markers for symbol. O(ln N)
  findAllPrefix(prefix): Return map {symbol: markers} for all symbols with
    prefix.  O(ln N + M)

###

parseMarker = (marker) ->
    range = marker.getBufferRange()
    return "(#{range.start.row}:#{range.start.column} #{range.end.row}:#{range.end.column})"

###*
Trie node, containing a character, markers (if the trie is a complete symbol),
and child nodes.
###
class Node
    constructor: ->
        @markers = []
        @children = {} # next letter -> node

exports.MarkerTrie = class MarkerTrie
    constructor: ->
        @root = new Node()

    _add: (node, symbol, marker, charIndex) ->
        unless node
            node = new Node()

        if charIndex == symbol.length
            utils.insertOrdered(marker, node.markers)
            # console.log "Inserted #{symbol}", marker, node.markers
        else
            # Else we still have characters to traverse
            ch = symbol[charIndex++]
            node.children[ch] = @_add(node.children[ch], symbol, marker, charIndex)

        return node

    # Collect (in symbolMap) all the points for symbols in this subtree
    # NB: Modifies symbolMap
    _collect: (node, prefix, symbolMap) ->
        return unless node

        if node.markers.length
            symbolMap[prefix] = node.markers

        for ch, child of node.children
            @_collect(child, prefix + ch, symbolMap)

    add: (symbol, marker) ->
        return unless symbol?.length
        # console.log "Adding", symbol, marker
        @_add(@root, symbol, marker, 0)

    # Return an ordered list of markers for symbol, or an empty list
    # if there are no markers.
    find: (symbol) ->
        node = @root
        charIndex = 0
        while node and charIndex < symbol.length
            ch = symbol[charIndex++]
            node = node.children[ch]

        return if node then node.markers else []

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

    # XXX: Modifies collection
    _dump: (node, collection, prefix) ->
        return unless node
        if node.markers.length
          collection[prefix] = node.markers.map(parseMarker)
        for ch, child of node.children
            @_dump(child, collection, prefix + ch)

    # prints a pretty string representation
    dump: ->
      collection = {}
      @_dump(@root, collection, '')
