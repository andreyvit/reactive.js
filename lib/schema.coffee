debug = require('debug')('reactive')
types = require('./types')


class RAttributeSchema

  constructor: (@modelSchema, @key, options) ->
    @type     = types.resolve(options.type ? 'any')
    @computed = options.computed ? no
    @default  = options.default

    @computeFunc = @modelSchema.modelClass.prototype["compute #{@key}"]
    if !!@computeFunc != !!@computed
      if @computed
        throw new Error "Missing compute func for computed property #{this}"

  toString: ->
    "#{@modelSchema}.attributes.#{@key}"

  preSet: (instance, value) ->
    if @computed then throw new Error "Cannot assign to a computed property #{this}"

    return @type.coerce(value)

  initializeInstance: (instance) ->
    instance.attributes[@key] = @_defaultValue()
    if @computeFunc
      instance.pleasedo "compute #{@key}", =>
        newValue = @computeFunc.call(instance)
        oldValue = instance.attributes[@key]
        if newValue != oldValue
          instance.attributes[@key] = newValue
          instance._changed(@key)

  _defaultValue: ->
    switch typeof @default
      when 'function'
        @default()
      when 'undefined'
        @type.defaultValue()
      else
        @default


class RModelSchema

  constructor: (@modelClass) ->
    @attributes = {}

    data = @modelClass.prototype.schema ? {}
    for key, options of data
      @attributes[key] =  @_createAttribute(key, options)

    @autoBlocks = []

    for key of @modelClass.prototype
      if $ = key.match /^automatically (.*)$/
        value = @modelClass.prototype[key]
        @autoBlocks.push [$[1], value]


  toString: ->
    "#{@modelClass.name}.schemaObj"

  initializeInstance: (instance) ->
    for own key, attrSchema of @attributes
      attrSchema.initializeInstance(instance)
    for [name, func] in @autoBlocks
      instance.pleasedo name, func.bind(instance)

  _createAttribute: (key, options) ->
    Object.defineProperty @modelClass.prototype, key,
      enumerable: yes
      get: -> @get(key)
      set: (value) -> @set(key, value)
    return new RAttributeSchema(this, key, options)

module.exports = RModelSchema
