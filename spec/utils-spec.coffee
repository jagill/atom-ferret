{insertOrdered, findPrevNext} = require '../lib/utils'
{Point} = require 'atom'

describe 'insertOrdered', ->
  it 'should insert an object into an empty array', ->
    a = []
    p = new Point(2, 4)
    insertOrdered(p, a)
    expect(a.length).toBe(1)
    expect(a[0]).toBe(p)

  it 'should insert a sequence, ordering it', ->
    a = []
    p0 = new Point(0, 0)
    p1 = new Point(2, 4)
    p2 = new Point(2, 7)
    p3 = new Point(3, 1)
    insertOrdered(p2, a)
    insertOrdered(p1, a)
    insertOrdered(p3, a)
    insertOrdered(p0, a)
    expect(a).toEqual([p0, p1, p2, p3])

describe 'findPrevNext', ->
  p = null
  beforeEach ->
    p = new Point(2, 4)

  it 'should return nothing when list is empty', ->
    pn = findPrevNext p, []
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next).toBeUndefined("next is #{pn.next}")

  it 'should give nothing when list has only single equal point', ->
    pn = findPrevNext p, [ new Point(2, 4) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next).toBeUndefined("next is #{pn.next}")

  it 'should give only next when list has only single later point', ->
    pn = findPrevNext p, [ new Point(3, 0) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(0)

  it 'should give only next when list is all later points', ->
    pn = findPrevNext p, [ new Point(3, 0), new Point(10, 10) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(0)

  it 'should give only prev when list has only single earlier point', ->
    pn = findPrevNext p, [ new Point(1, 5) ]
    expect(pn.next).toBeUndefined("next is #{pn.next}")
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(5)

  it 'should give only prev when list is all earlier points', ->
    pn = findPrevNext p, [ new Point(1, 0), new Point(1, 5) ]
    expect(pn.next).toBeUndefined("next is #{pn.next}")
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(5)

  it 'should give only prev when final point is position', ->
    pn = findPrevNext p, [ new Point(1, 0), new Point(2, 4) ]
    expect(pn.next).toBeUndefined("next is #{pn.next}")
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(0)

  it 'should give only next when first point is position', ->
    pn = findPrevNext p, [ new Point(2, 4), new Point(3, 6) ]
    expect(pn.prev).toBeUndefined("prev is #{pn.prev}")
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(6)

  it 'should give adjacent prev/next when it is in the array', ->
    pn = findPrevNext p, [ new Point(1, 3), new Point(2, 4), new Point(3, 6) ]
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(3)
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(6)

  it 'should give appropriate prev/next when it is not in the array', ->
    pn = findPrevNext p, [ new Point(1, 3), new Point(3, 6) ]
    expect(pn.prev.row).toBe(1)
    expect(pn.prev.column).toBe(3)
    expect(pn.next.row).toBe(3)
    expect(pn.next.column).toBe(6)
