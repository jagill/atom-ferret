FerretView = require './ferret-view'
{CompositeDisposable, Range} = require 'atom'
{SymbolIndex} = require './symbols'
utils = require './utils'

module.exports = Ferret =
  ferretView: null
  findPanel: null
  subscriptions: null
  symbolIndex: null
  marks: {}

  activate: (state) ->
    @ferretView = new FerretView(state.ferretViewState)
    @findPanel = atom.workspace.addBottomPanel(item: @ferretView, visible: false, className: 'tool-panel panel-bottom')
    @ferretView.setPanel(@findPanel)

    @symbolIndex = new SymbolIndex()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:test': => @test()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:testDestroy': => @testDestroy()


    @ferretView.onDidStopChanging (text) =>
      @markResults text

  deactivate: ->
    @findPanel.destroy()
    @subscriptions.dispose()
    @ferretView.destroy()

  serialize: ->
    ferretViewState: @ferretView.serialize()

  toggle: ->
    if @findPanel.isVisible()
      @findPanel.hide()
    else
      @findPanel.show()
    # if @decoration
    #   @testDestroy()
    # else
    #   @test()

  generate: (editor) ->
    editor = editor or atom.workspace.getActiveTextEditor()
    console.log "Generating for path", editor.getPath()
    @symbolIndex.parse editor.getPath(), editor.getText(), editor.getGrammar()
    # console.log "Generated", @symbolIndex.findAllPositions(editor.getPath())

  retrieve: (word, editor) ->
    return {} unless word
    editor = editor or atom.workspace.getActiveTextEditor()
    filepath = editor.getPath()
    unless filepath of @symbolIndex
      @generate editor
    return @symbolIndex.findPositionsForPrefix(filepath, word)

  markResults: (text) ->
    console.log "Marking results for |#{text}|"
    return unless text
    prefix = text  # Eventually do some processing.

    if name of @marks
      mark.destroy() for mark in @marks[name]

    editor = atom.workspace.getActiveTextEditor()
    positionMap = @retrieve prefix, editor
    console.log "Positions for #{prefix}", positionMap
    for symbol, positions of positionMap
      symbolMarks = []
      for pos in positions
        endSymbol = utils.endOfWord pos, symbol
        symbolRange = new Range(pos, endSymbol)
        console.log "Using range", symbolRange
        symbolMarker = editor.markBufferRange(symbolRange, invalidate: 'touch')
        decoration = editor.decorateMarker(symbolMarker,
              {type: 'highlight', class: "highlight-selected"})
        symbolMarks.push symbolMarker
        console.log "Added decoration", decoration

        endPrefix = utils.endOfWord pos, prefix
        prefixRange = new Range(pos, endPrefix)
        prefixMarker = editor.markBufferRange(prefixRange, invalidate: 'inside')
        editor.decorateMarker(prefixMarker,
              {type: 'highlight', class: "highlight-red"})
        symbolMarks.push prefixMarker

      @marks[symbol] = symbolMarks

  test: ->
    console.log "Making decoration"
    editor = atom.workspace.getActiveTextEditor()
    range = editor.getSelectedBufferRange()
    marker = editor.markBufferRange(range, invalidate: 'never')
    @decoration = editor.decorateMarker(marker, type: 'highlight', class: "highlight-green")
    # @decoration = editor.decorateMarker(marker, type: 'line', class: "line-green")
    console.log "Made decoration", @decoration

  testDestroy: ->
    @decoration.getMarker().destroy()
    @decoration = null
