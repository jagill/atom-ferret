{CompositeDisposable, Range, TextEditor} = require 'atom'
utils = require './utils'
FerretView = require './ferret-view'
{SymbolIndex} = require './symbols'
{SymbolMarks} = require './symbol-marks'
{Decorator} = require './decorator'


module.exports = Ferret =
  ferretView: null
  findPanel: null
  subscriptions: null
  symbolIndex: null
  marks: {}

  activate: (state) ->
    console.log 'Activating ferret'
    @ferretView = new FerretView(state.ferretViewState)
    @findPanel = atom.workspace.addBottomPanel(item: @ferretView, visible: false, className: 'tool-panel panel-bottom')
    @ferretView.setPanel(@findPanel)

    @symbolIndex = new SymbolIndex()
    # Keep track of highlight marks, so we can destroy them properly
    @marks = new SymbolMarks(@symbolIndex)

    @searchMarks = []

    # This is the new method; not quite ready.
    @decorator = new Decorator(@symbolIndex)
    # XXX: DEBUG
    global.symbolIndex = @symbolIndex
    global.decorator = @decorator

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:prevSymbol': => @prevSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:nextSymbol': => @nextSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:firstSymbol': => @firstSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:markSymbol': => @markSymbol()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:clearMarks': => @clearMarks()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:clearAllMarks': => @clearAllMarks()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:toggle': => @test()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:test': => @test()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ferret:testDestroy': => @testDestroy()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidStopChanging =>
        console.log "Re-generating for #{editor?.getPath()}"
        @generate editor
        @marks.regenerate()
        # @decorator.regenerate(path)

    @subscriptions.add atom.workspace.observePanes (pane) =>
      editor = pane.getActiveItem()
      if editor and editor instanceof TextEditor
        @generate editor
      @subscriptions.add pane.onDidChangeActiveItem (editor) =>
        # This can be undefined if the pane closes.
        return unless editor and editor instanceof TextEditor
        console.log "ZZZ Changed active editor:", editor.getPath()
        @generate editor
        @marks.regenerate()

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
    filepath = editor.getPath()

    console.log "Generating for path", filepath
    @symbolIndex.parse filepath, editor.getText(), editor.getGrammar()
    # console.log "Generated", @symbolIndex.findAllPositions(editor.getPath())

  retrieve: (prefix, editor) ->
    return {} unless prefix
    editor = editor or atom.workspace.getActiveTextEditor()
    filepath = editor.getPath()
    unless filepath of @symbolIndex
      @generate editor
    return @symbolIndex.findPositionsForPrefix(filepath, prefix)

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

  _gotoNextPrevSymbol: (prev=true) ->
    word = utils.getCurrentWord()
    return unless word
    editor = atom.workspace.getActivePaneItem()
    positions = @symbolIndex.findPositions editor.getPath(), word
    currentPos = editor.getCursorBufferPosition()
    prevNext = utils.findPrevNext currentPos, positions
    if prev
      pos = prevNext.prev
      if pos and currentPos.isLessThanOrEqual(utils.endOfWord(pos, word))
        # We're inside this word, let's actually go to two previous.
        twoPrev = utils.findPrevNext(pos, symbols).prev
        pos = twoPrev or pos
    else
      pos = prevNext.next
    editor.setCursorBufferPosition pos if pos

  prevSymbol: ->
    @_gotoNextPrevSymbol true

  nextSymbol: ->
    @_gotoNextPrevSymbol false

  firstSymbol: ->
    word = utils.getCurrentWord()
    editor = atom.workspace.getActivePaneItem()
    positions = @symbolIndex.findPositions editor.getPath(), word
    pos = positions[0]
    editor.setCursorBufferPosition pos if pos

  clearMarks: ->
    word = utils.getCurrentWord()
    @marks.clear word

  clearAllMarks: ->
    @marks.clearAll()

  markSymbol: ->
    word = utils.getCurrentWord()
    return unless word
    if @marks.has word
      console.log 'Clearing marks for ' + word
      @marks.clear word
      return
    @marks.names.push word
    @marks.regenerate()

  test: ->
    word = utils.getCurrentWord()
    if @decorator.has(word)
      console.log "Undoing decoration for #{word}"
      @decorator.undecorate(word)
    else
      console.log "Making decoration for #{word}"
      @decorator.colorSymbol(word)

  testDestroy: ->
    word = utils.getCurrentWord()
    console.log "Undoing decoration for #{word}"
    @decorator.undecorate(word)
