{RangeTrie} = require '../lib/range-trie'
{Point} = require 'atom'


describe 'RangeTrie', ->
  describe 'find', ->

    it 'should return empty list when trie is empty', ->
      symbols = new RangeTrie()
      expect(symbols.find('foo')).toEqual([])

    it 'should return empty list when trie doesnt have symbol', ->
      symbols = new RangeTrie()
      symbols.add('bar', new Point(2, 4))
      expect(symbols.find('foo')).toEqual([])

    it 'should return a point inserted for a symbol', ->
      symbols = new RangeTrie()
      p = new Point(2, 4)
      symbols.add('foo', p)
      expect(symbols.find('foo')).toEqual([p])

    it 'should return two points in order', ->
      symbols = new RangeTrie()
      p1 = new Point(2, 4)
      p2 = new Point(1, 1)
      symbols.add('foo', p1)
      symbols.add('foo', p2)
      expect(symbols.find('foo')).toEqual([p2, p1])

  describe 'findPrefix', ->
    it 'should return nothing if no symbols have the prefix', ->
      symbols = new RangeTrie()
      symbols.add('foo', new Point(3, 3))
      expect(symbols.findPrefix('ba')).toEqual({})

    it 'should return symbols with the given prefix', ->
      symbols = new RangeTrie()
      truthP1 = new Point(2, 4)
      truthP2 = new Point(1, 1)
      truckP1 = new Point(10, 0)
      symbols.add('truth', truthP1)
      symbols.add('truth', truthP2)
      symbols.add('truck', truckP1)
      expect(symbols.findPrefix('tru')).toEqual({
        truth: [truthP2, truthP1]
        truck: [truckP1]
      })
