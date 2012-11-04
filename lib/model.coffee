{ EventEmitter } = require 'events'
RModelSchema = require './schema'

class RModel extends EventEmitter

  constructor: ->
    unless @constructor.name
      throw new Error "R.Model must have a name"

    unless @constructor.schemaObj?.modelClass is @constructor
      @constructor.schemaObj = new RModelSchema(@constructor)

    @_id = @universe.uniqueId(@constructor.name)

    @attributes     = {}
    @_changedAttrs  = {}
    @_changePending = no

    @_blocks = []  # will be populated by RBlock

    # format: attr1, subscriber1, attr2, subscriber2, ...
    @_subscribers = []

    @constructor.schemaObj.initializeInstance(this)

    @initialize()

  toString: -> @_id

  initialize: ->

  dispose: ->
    for block in @_blocks
      block.dispose()
    @_blocks = []

  get: (attr) ->
    @universe.dependency(this, attr)
    @attributes[attr]

  has: (attr) ->
    @attributes[attr]?

  set: (attr, value) ->
    unless attrSchema = @constructor.schemaObj.attributes[attr]
      throw new Error "Unknown attribute #{@constructor.name}.#{attr}"
    value = attrSchema.preSet(this, value)

    @attributes[attr] = value
    @_changed(attr)

  _changed: (attr) ->
    unless @_changedAttrs[attr]
      @_changedAttrs[attr] = yes
      unless @_changePending
        @_changePending = yes
        @universe._internal_modelChanged(this)


  subscribe: (subscriber, attribute) ->
    @_subscribers.push subscriber, attribute

  unsubscribe: (subscriber) ->
    subscribers = @_subscribers
    index = 0
    while (index = subscribers.indexOf(subscriber, index)) >= 0
      subscribers.splice index, 2

  subscribersTo: (attribute) ->
    subscribers = @_subscribers
    result = []
    index  = -1
    while (index = subscribers.indexOf(attribute, index + 1)) >= 0
      result.push subscribers[index - 1]
    return result


  _internal_startProcessingChanges: ->
    @_changePending = no
    attrs = @_changedAttrs
    @_changedAttrs = {}
    return attrs


  # shared instance of R.Universe; initially set to a dummy implementation, will be reset by
  # R.Universe constructor; can be overridden in subclass prototypes or even per instance
  dummyNextUniqueId = 1
  universe: { _internal_modelChanged: (->), destroy: (->), uniqueId: (-> "c#{dummyNextUniqueId++}"), dependency: (->), _internal_scheduleBlock: ((block) -> process.nextTick -> block.execute()) }


module.exports = RModel
