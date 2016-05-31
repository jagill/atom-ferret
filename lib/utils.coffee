{Point} = require 'atom'

compare = (a, b) ->
  return a.compare(b)

###*
Find the index of marker m in the ordered list markers, or find the
index where it should be.  That is, the index `idx` such that
`markers[idx-1]` is before p, and `markers[idx+1]` is after p.
This is modified in the obvious way if `idx` is either `0` or
`markers.length - 1`.
###
exports.findIndex = findIndex = (m, markers) ->
  beg = 0
  end = markers.length - 1
  while beg < end
    mid = (beg + end) // 2
    switch compare(m, markers[mid])
      when 0
        beg = end = mid
      when 1
        beg = mid + 1
      when -1
        end = mid - 1
  return beg

###*
Insert a point p into an ordered list of markers, maintaining order.
###
exports.insertOrdered = (m, markers) ->
  idx = findIndex(m, markers)
  if idx == markers.length
    markers.push(m)
  else
    switch compare(m, markers[idx])
      when 0
        # Replace the existing marker
        markers.splice(idx, 1, m)
      when -1
        # Insert before existing marker
        markers.splice(idx, 0, m)
      when 1
        # Insert after existing marker
        markers.splice(idx + 1, 0, m)

###*
Given a position (point) and an ordered list of points, find the points in the
list that are immediately before and after the position.  These can be
undefined, for example if there is no point in the list before (or after) the
position.

Return a map {prev:, next:} .
###
exports.findPrevNext = (p, positions) ->
  if positions.length == 0
    return {prev: undefined, next: undefined}

  idx = findIndex(p, positions)
  switch p.compare(positions[idx])
    when 0
      return {prev: positions[idx-1], next: positions[idx+1]}
    when -1
      return {prev: positions[idx-1], next: positions[idx]}
    when 1
      return {prev: positions[idx], next: positions[idx+1]}

# Get word under cursor, if any.
wordRe = /\w+/
exports.getCurrentWord = ->
  editor = atom.workspace.getActivePaneItem()
  word = editor.getWordUnderCursor()
  # Sometimes the word has weird cruft like '[foo'; clean it up
  match = wordRe.exec(word)
  return match and match[0]

# Return the point corresponding to the end of the word.
# wordBegin:Point is the beginning of the word
# word:String is the word
exports.endOfWord = (wordBegin, word) ->
  return new Point(wordBegin.row, wordBegin.column + word.length)
