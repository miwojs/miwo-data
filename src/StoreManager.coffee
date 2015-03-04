BaseManager = require './BaseManager'
Store = require './Store'

class StoreManager extends BaseManager


	create: (name) ->
		store = super(name)
		if !store.isStore
			throw new Error("Created store is not instance of Miwo.data.Store")
		if !store.name
			store.name = name
		return store


module.exports = StoreManager