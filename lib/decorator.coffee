{TextEditor} = require 'atom'


exports.Decorator = class Decorator
  constructor: (@symbolIndex) ->
    @decorationIndex = {}  # filepath: symbol: [decoration...]

  _assertParsed: (filepath) ->
    if not filepath of @symbolIndex
      throw new Error("Trying to access symbols for #{filepath}, but they haven't been generated yet.")

  colorSymbol: (symbol) ->
    for pane in atom.workspace.getPanes()
      editor = pane.getActiveItem()
      continue unless editor and editor instanceof TextEditor
      filepath = editor.getPath()
      console.log "Coloring #{symbol} in #{filepath}"
      if filepath not of @decorationIndex
        @decorationIndex[filepath] = {}
      decorations = @decorationIndex[filepath]
      if symbol not of @decorationIndex[filepath]
        @decorationIndex[filepath][symbol] = []

      decorations = @decorationIndex[filepath][symbol]
      markers = @symbolIndex.findPositions filepath, symbol
      for marker in markers
        decorations.push editor.decorateMarker(marker,
              {type: 'highlight', class: "highlight-selected highlight-green"})

  has: (symbol) ->
    editor = atom.workspace.getActiveTextEditor()
    filepath = editor.getPath()
    return filepath of @decorationIndex and
      symbol of @decorationIndex[filepath] and
      @decorationIndex[filepath][symbol].length > 0

  undecorate: (symbol) ->
    for filepath, symbolDecorations of @decorationIndex
      continue unless symbol of symbolDecorations
      for decoration in symbolDecorations[symbol]
        decoration.destroy()
      symbolDecorations[symbol] = []

  undecorateAll: ->
    for filepath, symbolDecorations of @decorationIndex
      for symbol, decorations of symbolDecorations[filepath]
        decoration.destroy() for decoration in decorations
        symbolDecorations[symbol] = []
