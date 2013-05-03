###
The way I have chosen to structure this file is as follows:

  o Whenever an action happens, send a message over the socket to the server
  o The server will broadcast the message to all sockets (including the sender)
  o Then all the sockets will update themselves

  o The methods with "Private" in their names are the ones that actually do the updating on the client side
  o The other ones are the methods who send the message to the server
###

url = "ws://" + window.location.host
socket = if window['MozWebSocket'] then new MozWebSocket(url) else new WebSocket(url)

tasks = null

#socket.onopen = () ->

socket.onmessage = (message) ->
	message = JSON.parse message.data
	if message.type == 'init'
		data = message.todos
		for entry in data
			t = new Task(entry[1], entry[0], entry[2])
			tasks.addInitialTasks t
	
	if message.type == 'new'
		data = message.text
		tasks.addTaskPrivate new Task(data[1], data[0], data[2])

	if message.type == 'delete'
		id = message.id
		
		task = tasks.getTaskByID parseInt(id)
		if task?
			tasks.deletePrivate task

	if message.type == 'complete' 

		tasks.completePrivate (tasks.getTaskByID (parseInt message.id))

	if message.type == 'uncomplete'
		
		tasks.uncompletePrivate (tasks.getTaskByID (parseInt message.id))

class Task
	constructor: (descr, id, finished) ->
		@description = ko.observable(descr)
		@ID = ko.observable(id)
		@isFinished = ko.observable(finished)

	print: () ->
		console.log (@description() + "..." + (parseInt @ID()) + "..." + @isFinished())


$ ->
	class TaskViewModel 
		#create the arrays
		constructor: () ->
			@complete = ko.observableArray []
			@incomplete = ko.observableArray []

		addTask: (str) =>
			socket.send JSON.stringify({type: "new", text:str})

		#add all the tasks when the page is refreshed (don't send any messages over the socket)
		addInitialTasks: (task) =>
			if(task.isFinished())
				@complete.push task
			else 
				@incomplete.push task

		addTaskPrivate: (task) =>
			if(task.isFinished())
				@complete.splice 0, 0, task
			else 
				@incomplete.splice 0, 0, task

		completeTask: (task) =>
			socket.send JSON.stringify({type: "complete", id: task.ID()})

		uncompleteTask: (task) =>
			socket.send JSON.stringify({type: "uncomplete", id: task.ID()})

		#move the task from the incomplete list to the FRONT of the complete list
		completePrivate: (task) =>
			@incomplete.remove task
			@complete.splice 0, 0, task
		
		#move the task from the complete list to the FRONT of the incomplete list
		uncompletePrivate: (task) =>
			@complete.remove task
			@incomplete.splice 0, 0, task

		delete: (task) =>
			socket.send JSON.stringify({type: "delete", id: parseInt(task.ID())})
		
		#just to be safe, remove the task from both lists
		deletePrivate: (task) =>
			@complete.remove task
			@incomplete.remove task

		#given an ID, iterate over both lists, and see if there is a task with a matching ID.
		#return the task if one exists
		#else return null
		getTaskByID: (id) =>
			retVal = null

			ko.utils.arrayForEach @incomplete(), (task) =>
				if task?
					if task.ID() == id 
						retVal = task

			ko.utils.arrayForEach @complete(), (task) =>
				if task?
					if task.ID() == id 
						retVal = task

			return retVal

	tasks = new TaskViewModel()

	ko.applyBindings tasks

	#listeners for the add new items
	$("#addNewBtn").click ->
		socket.send JSON.stringify({type: "new", text:$('#newTask').val()})
		$("#newTask").val('')

	$("#newTask").bind 'enterKey', () ->
			$('#addNewBtn').trigger('click')

		.keyup (e) ->
			if e.keyCode == 13
				$(this).trigger('enterKey')

