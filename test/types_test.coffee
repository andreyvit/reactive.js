{ ok, equal, deepEqual } = require 'assert'
types = require '../lib/types'

describe 'types', ->

  describe '.resolve', ->

    it "should resolve String into a string type", ->
      equal types.resolve(String).toString(), 'string'

    it "should resolve 'int' into an integer type", ->
      equal types.resolve('int').toString(), 'int'

    it "should resolve Array into array(any)", ->
      equal types.resolve(Array).toString(), "{ array: any }"

    it "should resolve { array: 'int' } into array(int)", ->
      equal types.resolve({ array: 'int' }).toString(), "{ array: int }"

  describe 'array(int).coerce', ->

    it "should turn [1, '2'] into [1, 2]", ->
      equal JSON.stringify(types.coerce([1, '2'], { array: 'int' })), JSON.stringify([1, 2])
