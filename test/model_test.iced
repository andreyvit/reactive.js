{ ok, equal, strictEqual } = require 'assert'
R             = require '../lib/reactive'


class FooModel extends R.Model
  schema:
    foo: {}


describe 'R.Model', ->

  it "should conform to EventEmitter protocol", (done) ->
    m = new FooModel()
    m.once 'foo', done
    m.emit 'foo'

  describe "#initialize()", ->
    it "should be able to call #get() and #set()", ->
      class Ruby extends FooModel
        initialize: ->
          @set 'foo', 42
          equal @get('foo'), 42
      m = new Ruby()
      equal m.get('foo'), 42

  describe "#get()", ->

    it "should return a value set via #set()", ->
      m = new FooModel()
      m.set('foo', 42)
      equal m.get('foo'), 42

  describe "#has()", ->

    it "should return no for undefined attributes", ->
      m = new FooModel()
      equal m.has('foo'), no

    it "should return no for attributes set to undefined", ->
      m = new FooModel()
      m.set('foo', undefined)
      equal m.has('foo'), no

    it "should return no for attributes set to null", ->
      m = new FooModel()
      m.set('foo', null)
      equal m.has('foo'), no

    it "should return yes for attributes set to anything else", ->
      m = new FooModel()
      m.set('foo', '')
      equal m.has('foo'), yes

  describe "#set()", ->

    it "should emit a change event on R.Universe", (done) ->
      u = new R.Universe()
      m = new FooModel()

      await
        u.once 'change', defer(model, attr)
        m.set 'foo', 42
      equal model, m
      equal attr, 'foo'

      u.destroy()
      done()

    it "should emit the change event asynchronously", (done) ->
      u = new R.Universe()
      m = new FooModel()

      u.once 'change', ->
        ok afterSet
        done()

      m.set 'foo', 42
      afterSet = yes

    it "should emit the change event once for any number of consecutive changes", (done) ->
      u = new R.Universe()
      m = new FooModel()

      count = 0
      u.on 'change', ->
        ++count
        equal m.get('foo'), 44
      u.then ->
        equal count, 1
        equal m.get('foo'), 44
        done()

      m.set 'foo', 42
      m.set 'foo', 43
      m.set 'foo', 44


  describe "accessors defined by a schema", ->

    it "should return a previously set value", ->
      u = new R.Universe()
      m = new FooModel()
      m.foo = 42
      equal m.foo, 42

    it "should emit a change event on write", (done) ->
      u = new R.Universe()
      m = new FooModel()

      await
        u.once 'change', defer(model, attr)
        m.foo = 42
      equal model, m
      equal attr, 'foo'

      u.destroy()
      done()


  describe "with default values", ->

    it "should initialize a property with the specified default value", ->
      class BarModel extends R.Model
        schema:
          foo: { type: 'int', default: 42 }
      u = new R.Universe()
      m = new BarModel()
      strictEqual m.foo, 42

    it "should initialize a property with its type's default value when no explicit default is specified", ->
      class BarModel extends R.Model
        schema:
          foo: { type: 'int' }
      u = new R.Universe()
      m = new BarModel()
      strictEqual m.foo, 0

    it "should initialize a property with null when neither type nor explicit default is specified", ->
      class BarModel extends R.Model
        schema:
          foo: {}
      u = new R.Universe()
      m = new BarModel()
      strictEqual m.foo, null
