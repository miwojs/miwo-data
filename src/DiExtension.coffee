StoreManager = require './StoreManager'
ProxyManager = require './ProxyManager'
EntityManager = require './EntityManager'


class DataExtension extends Miwo.di.InjectorExtension


	init: ->
		@setConfig
			stores: {}
			entities: {}
		return


	build: (injector) ->
		namespace = window[injector.params.namespace]
		namespace.entity = {}  if !namespace.entity
		namespace.store = {}  if !namespace.store

		injector.define 'storeMgr', StoreManager, (service)=>
			for name, store of @config.stores
				service.define(name, store)
				namespace.store[name.capitalize()] = store
			return

		injector.define 'entityMgr', EntityManager, (service)=>
			for name, entity of @config.entities
				service.define(name, entity)
				namespace.entity[name.capitalize()] = entity
			return

		injector.define 'proxyMgr', ProxyManager, (service)=>
			# setup proxies from entities
			for name, entity of @config.entities
				if entity.proxy
					service.define(name, entity.proxy)
					entity.proxy = name
			return
		return



module.exports = DataExtension