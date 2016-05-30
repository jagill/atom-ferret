{Point} = require 'atom'

###*
Find the index of p in the ordered list positions, or find the
index where it should be.  That is, the index `idx` such that
`positions[idx-1]` is before p, and `positions[idx+1]` is after p.
This is modified in the obvious way if `idx` is either `0` or
`positions.length - 1`.
###
exports.findIndex = findIndex = (p, positions) ->
  beg = 0
  end = positions.length - 1
  while beg < end
    mid = (beg + end) // 2
    switch p.compare(positions[mid])
      when 0
        beg = end = mid
      when 1
        beg = mid + 1
      when -1
        end = mid - 1
  return beg

###*
Insert a point p into an ordered list of positions, maintaining order.
###
exports.insertOrdered = (p, positions) ->
  idx = findIndex(p, positions)
  if idx == positions.length
    positions.push(p)
  else
    switch p.compare(positions[idx])
      when 0, -1
        positions.splice(idx, 0, p)
      when 1
        positions.splice(idx + 1, 0, p)

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

# Return the point corresponding to the end of the word.
# wordBegin:Point is the beginning of the word
# word:String is the word
exports.endOfWord = (wordBegin, word) ->
  return new Point(wordBegin.row, wordBegin.column + word.length)
