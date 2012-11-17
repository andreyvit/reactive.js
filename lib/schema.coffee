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

  constructor: (@universe, originalModelClass) ->
    @modelClass = @_createSingletonClass(originalModelClass)

    @attributes = {}
    @autoBlocks = []

    @_handleMagicKeys(@modelClass)


  toString: ->
    "#{@modelClass.name}.schemaObj"


  mixin: (mixinClasses...) ->
    # TODO: create a singleton class if not already done
    for mixinClass in mixinClasses
      @_extendModel(mixinClass)
      @_handleMagicKeys(mixinClass)

  create: (options) ->
    result = new @modelClass(options)


  _createSingletonClass: (modelClass) ->
    ## This would be a sane way to do this, if Function.name wasn't unassignable
    # singletonClass = (args...) ->
    #   modelClass.apply(this, args)
    # singletonClass.name = modelClass.name

    # so let's do it the insane way
    global.REACTIVE_CLASS_CREATION_HACK = modelClass
    singletonClass = eval("(function(modelClass) { return function #{modelClass.name}() { modelClass.apply(this, arguments); }; })(global.REACTIVE_CLASS_CREATION_HACK);")
    delete global.REACTIVE_CLASS_CREATION_HACK;

    singletonClass.isSingletonClass = yes
    for own k, v of modelClass
      singletonClass[k] = v

    singletonClass.prototype = { constructor: singletonClass }
    singletonClass.prototype.__proto__ = modelClass.prototype

    singletonClass.schemaObj = this
    singletonClass.prototype.universe = @universe

    singletonClass


  _extendModel: (mixinClass) ->
    for own k, v of mixinClass
      if @modelClass.hasOwnProperty(k)
        throw new Error "Key #{JSON.stringify(k)} is already defined on model #{@modelClass.name}, cannot redefine in mixin #{mixinClass.name}"
      @modelClass[k] = v
    for k, v of mixinClass.prototype when !(k is 'schema')
      if @modelClass.prototype.hasOwnProperty(k)
        throw new Error "Prototype key #{JSON.stringify(k)} is already defined on model #{@modelClass.name}, cannot redefine in mixin #{mixinClass.name}"
      @modelClass.prototype[k] = v


  _handleMagicKeys: (mixinClass) ->
    prototype = mixinClass.prototype

    data = prototype.schema ? {}
    for key, options of data
      @attributes[key] =  @_createAttribute(key, options)

    for key of prototype
      if $ = key.match /^automatically (.*)$/
        value = prototype[key]
        @autoBlocks.push [$[1], value]


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
