BaseManager = require './BaseManager'
Proxy = require './Proxy'

class ProxyManager extends BaseManager


	define: (name, klass) ->
		if !Type.isFunction(klass) && !Type.isObject(klass)
			throw new Error("Bad defined type '#{name}' in '#{this}'. Parameter should by function or object")
		@types[name] = klass
		return this


	create: (name) ->
		if !@types[name]
			throw new Error("Undefined type '#{name}' in #{this}")
		return @createProxy(@types[name])


	createProxy: (config) ->
		if Type.isFunction(config)
			proxy = new config()
		if Type.isObject(config)
			proxy = new Proxy(config)
		if !proxy.isProxy
			throw new Error("Created proxy is not instance of Miwo.data.Proxy")
		return proxy


module.exports = ProxyManager