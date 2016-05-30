{CompositeDisposable} = require 'atom'
{View, TextEditorView} = require 'atom-space-pen-views'


module.exports =
class FerretView extends View
  subscriptions: null
  findEditor: null
  panel: null

  @content: ->
    @findEditor = atom.workspace.buildTextEditor
      mini: true
      placeholderText: 'Find in current buffer'

    @div class: 'ferret', =>
      @subview 'findEditor', new TextEditorView(editor: @findEditor)

  initialize: (serializeState) ->
    @subscriptions = new CompositeDisposable()

    @subscriptions.add atom.commands.add @findEditor.element,
      'core:confirm': => @panel?.hide()
      'core:close': => @panel?.hide()
      'core:cancel': => @panel?.hide()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @subscriptions?.dispose()

  setPanel: (@panel) ->
    @subscriptions.add @panel.onDidChangeVisible (visible) =>
      if visible then @didShow() else @didHide()

  didShow: ->
    @findEditor.focus()

  didHide: ->
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.focus()

  onDidStopChanging: (callback) ->
    @findEditor.model.onDidStopChanging =>
      contents = @findEditor.getText()
      callback contents

  markResults: ->
    findPattern = @findEditor.getText()
