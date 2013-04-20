# Darwin.Base is the common parent of all Darwin classes.
#
# You can use it as well in any of your lib classes to
# benefits of its features :
#
# * option pattern
# * class events
# * mixins
#
#
# # Option pattern
#
# Any class inheriting from Darwin.Base can declare options
# that propagate to children classes, but not to parent classes,
# much like rails' `#class_attribute`. Observe the following :
#
# ```coffee
# class MyParentClass extends Darwin.Base
#   @options {
#     foo: 'Foo'
#   }
#
# class MyChildClass extends MyParentClass
#   @options {
#     foo: 'overriden foo'
#     bar: 'bar'
#   }
#
# class MyOtherChildClass extends MyParentClass
#   @options {
#     bar: 'other bar'
#   }
#
# new MyParentClass().options.foo       # => 'Foo'
# new MyChildClass().options.foo        # => 'overriden foo'
# new MyOtherChildClass().options.foo   # => 'Foo'
# new MyChildClass().options.bar        # => 'bar'
# new MyParentClass().options.bar       # => undefined
# ```
#
# Additionnaly, options can be overriden at initialization time :
#
# ```coffee
# new MyChildClass( bar: 'hello' ).options.bar  # => 'hello'
# ```
#
# If you override the constructor methods, don't forget to accept
# options parameter and call super with it :
#
# ```coffee
# class MyClass extends Darwin.Base
#   constructor: ( options ) ->
#     super( options )
#     # do stuff
# ```
#
#
# # Class events
#
# With jQuery, you can only bind and fire events on DOM elements.
#
# Darwin.Base provides a mean to attach events on classes :
#
# ```coffee
# class MyClass extends Darwin.Base
#   @options {
#     my_name: 'Joe'
#   }
#
#   say_hi: ->
#     @trigger( 'said', "Hi, my name is #{@options.my_name}." )
#
# my_instance = new MyClass()
# my_instance.on( 'said', ( message ) -> ( console.log( message ) ) )
# my_instance.say_hi() # logs : Hi, my name is Joe.
# ```
#
# This allows to easily encapsulate features in classes and have them
# to communicate.
#
#
# # Mixins
#
# A feature that coffeescript lacks of is the ability to include or
# extend mixins. Darwin.Base provides that :
#
# ```coffee
# InstanceMethods =
#   do_something: ->
#     console.log 'I did something.'
#
#   do_nothing: ->
#     console.log 'I swear I did nothing.'
#
#
# ClassMethods =
#   foo: ->
#     console.log 'foo'
#
#   bar: ->
#     console.log 'bar'
#     
#
# class MyClass extends Darwin.Base
#   @include InstanceMethods
#   @extend  ClassMethods
#   
# my_instance = new MyClass()
# my_instance.do_something()  # logs : 'I did something.'
# MyClass.foo()               # logs : 'foo'
# ```
#
# Just like ruby modules, special methods allow you to
# operate after module is included or extended :
#
# ```coffee
# InstanceMethods =
#   included: ->
#     @extend ClassMethods
#
#   do_something: ->
#     console.log 'I did something.'
#
#   do_nothing: ->
#     console.log 'I swear I did nothing.'
#
#
# ClassMethods =
#   extended: ->
#     console.log 'extended'
#
#   foo: ->
#     console.log 'foo'
#
#   bar: ->
#     console.log 'bar'
#     
#
# class MyClass extends Darwin.Base
#   @include InstanceMethods
#   
# my_instance = new MyClass() # logs : 'extended'
# my_instance.do_something()  # logs : 'I did something.'
# MyClass.foo()               # logs : 'foo'
# ```
#
reserved_keywords = [ 'extended', 'included' ]

class Darwin.Base
  @options: ( options ) ->
    parent_options = @__super__.constructor._options

    if parent_options?
      @_options = $.extend true, {}, parent_options, options
    else
      @_options = options


  @extend: ( obj ) ->
    for key, value of obj when key not in reserved_keywords
      @[ key ] = value

    obj.extended?.apply(@)
    @


  @include: ( obj ) ->
    for key, value of obj when key not in reserved_keywords
      @::[ key ] = value

    obj.included?.apply(@)
    @


  constructor: ( options ) ->
    @_bound = {}

    @options = $.extend( {}, @constructor._options, options )

    if @options.dependencies?
      for own name, dependency of @options.dependencies
        @[ name ] = dependency


  bind: ( event_name, callback ) ->
    @_bound[ event_name ] ?= []
    @_bound[ event_name ].push( callback )


  on: ( event_name, callback ) ->
    @bind( event_name, callback )


  one: ( event_name, callback ) ->
    callback = =>
      @unbind event_name, callback

    @bind event_name, callback


  unbind: ( event_name, callback ) ->
    if @_bound[ event_name ]
      if callback
        $.each @_bound[ event_name ], ( i, bound ) ->
          if bound == callback
            delete @_bound[ event_name ][ i ]

      else
        delete @_bound[ event_name ]


  unbind_all: ->
    @_bound = {}


  trigger: ( event_name, params... ) ->
    if @_bound[ event_name ]
      for own callback in @_bound[ event_name ]
        callback( params... )
