webSocketServer = (require 'ws').Server
http = require 'http'
express = require 'express'
todoList = require './todoList'
_ = require 'underscore'

app = express()
list = new todoList()

#server will automatically look here for requested files
app.use(express.static(__dirname + "/public"));

server = http.createServer app 
port = 4000

server.listen port 

wss = new webSocketServer({server: server})

#this array hold all active sockets, so we can broadcast
sockets = []
i = 0

#When a socket connects, add it to the list of sockets, and add all the listeners
wss.on "connection", (sock) ->

	#when a new socket connects, send the todolist so it can generate it's client side copy
	sock.send JSON.stringify({type:'init', todos: list.generateJSON()})
	sock.num = i
	sockets[i++] = sock
	
	#listen for messages from clients
	sock.on "message", (message) ->
		message = JSON.parse(message)

		if message.type == "uncomplete"
			list.switch parseInt(message.id, null), false
			broadcast JSON.stringify({type:"uncomplete", id:message.id, isChecked:false})

		else if message.type == "complete"
			list.switch parseInt(message.id, null), true
			broadcast JSON.stringify({type:"complete", id:message.id, isChecked:true})

		else if message.type == "delete"
			id = parseInt(message.id, null)
			list.remove list.getByID(id)
			broadcast JSON.stringify({type:"delete",id:id})

		else if message.type == "new"
			data = message.text
			newItem = list.add data

			broadcast JSON.stringify({type: "new", text: newItem.data()})
	#when a socket is closed, remove it from the array (set to null)
	sock.on "close", () ->
		sockets[sock.num] = null

#send the command to all open sockets that are not null
broadcast = (command) =>
		try
			_.each sockets, (s)=>
				if s != null 
					s.send(command)
		catch error
			console.log error
