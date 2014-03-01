RcFinder = require('rcfinder')
jshint = require('jshint').JSHINT
jshintcli = require('jshint/src/cli')
Subscriber = require('emissary').Subscriber
IconView = require('./icon-view')

class JsHinter extends Subscriber
  activate: (state) ->
    atom.workspaceView.command 'jshint:hint', =>
      @hint()

    atom.workspace.eachEditor (editor) =>
      @setEvents(editor)

  setEvents: (editor) ->
    buffer = editor.getBuffer()
    @subscribe buffer, 'saved', =>
      @hint() if @isValidFile(editor)

  hint: ->
    rcFinder = new RcFinder '.jshintrc',
      loader: (path) ->
        cfg = jshintcli.loadConfig(path)
        delete cfg.dirname
        return cfg

    editor = atom.workspace.getActiveEditor()
    editorView = atom.workspaceView.getActiveView()
    config = rcFinder.find(editor.getUri())

    return unless editor?
    console.log editor.getGrammar().scopeName

    unless @isValidFile(editor)
      console.warn("Cannot JSHint '#{editor.getUri() ? 'untitled'}'")
      return

    editorView.resetDisplay()
    @resetGutter(editorView)
    jshint(editor.getText(), config)

    @handleError(editor, editorView, error) for error in jshint.errors

  isValidFile: (editor) ->
    editor.getGrammar().scopeName is "source.js"

  handleError: (editor, editorView, error) ->
    row = error.line-1
    gutter = editorView.gutter
    bufferRange = editor.bufferRangeForBufferRow(row)
    bufferRange.start.column = bufferRange.end.column = error.character
    screenRange = editor.screenRangeForBufferRange(bufferRange)
    editorView = atom.workspaceView.getActiveView()
    editorView.lineElementForScreenRow(screenRange.start.row)
    .css('background-color', 'rgba(255,0,0,0.2)')
    console.log(error)
    gutterRow = gutter.find(gutter.getLineNumberElement(row))

    gutterRow
    .find( '.icon-right').hide()

    gutterRow.append new IconView(title: error.reason)


  resetGutter: (editorView) ->
    editorView.gutter.find('.icon-alert').remove()
    editorView.gutter.find('.icon-right').show()

module.exports = new JsHinter()
