{Point, Range, TextEditor} = require 'atom'
utils = require './utils'

exports.SymbolMarks = class SymbolMarks
  constructor: (@symbolIndex) ->
    # Names are the list of names we want to mark.  This is the point of truth.
    @names = []
    # These are the actual UI marks used; we generate this from @names.
    # marks = name:{color:, paths:{path:[marks]}}
    @marks = {}
    # Assign colors; put the name in the same location as the color above
    @assignedColors = []

  # Return the color for name, or the first unassigned color index.
  # If all colors are full, return -1
  _getColorIndex: (name) ->
    emptyIndex = -1
    for assignedName, i in @assignedColors
      if assignedName?
        if assignedName == name
          # Assigned to name already
          return i
        else
          # Assigned to another name, move on
          continue
      else
        # Record this index if it's empty
        emptyIndex = i if emptyIndex == -1
    if emptyIndex == -1
      # If there is no empty index, increase the array.
      emptyIndex = @assignedColors.length

    # We have an empty index, use it.
    @assignedColors[emptyIndex] = name
    return emptyIndex

  _removeName: (name) ->
    index = @names.indexOf name
    @names.splice(index, 1) if index > -1
    index = @assignedColors.indexOf name
    @assignedColors[index] = undefined if index > -1

  clear: (name) ->
    return unless name of @marks
    mark.destroy() for mark in @marks[name]
    delete @marks[name]
    @_removeName name

  clearAll: ->
    for name of @marks
      @clear name

  # Do we have marks for the given name
  has: (name) ->
    return @names.indexOf(name) > -1

  mark: (name) ->
    colorIndex = @_getColorIndex name
    symbolMarks = []
    for pane in atom.workspace.getPanes()
      editor = pane.getActiveItem()
      continue unless editor and editor instanceof TextEditor
      positions = @symbolIndex.findPositions editor.getPath(), name
      for pos in positions
        endPos = utils.endOfWord pos, name
        range = new Range(pos, endPos)
        # marker = editor.markBufferRange(range, invalidate: 'touch')
        marker = editor.markBufferRange(range, invalidate: 'inside')
        decoration = editor.decorateMarker(marker,
              {type: 'highlight', class: "highlight-selected highlight-color#{colorIndex+1}"})
        symbolMarks.push marker

    if name of @marks
      mark.destroy() for mark in @marks[name]

    @marks[name] = symbolMarks

  regenerate: ->
    @mark name for name in @names
