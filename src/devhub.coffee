{Adapter, TextMessage} = require 'hubot'
{EventEmitter} = require 'events'

class Devhub extends Adapter
  send: (envelope, strings...) ->
    old_avatar  = @bot.avatar
    if envelope.avatar?
      @bot.avatar = envelope.avatar
    @bot.send str for str in strings
    @bot.avatar  = old_avatar
    @bot.reset_avatar()

  run: ->
    options =
      name:   process.env.HUBOT_DEVHUB_NAME
      url:   process.env.HUBOT_DEVHUB_URL

    @bot = new DevhubStreaming options, @robot

    @bot.on 'message', (userId, message, room_id) =>
      name_re = new RegExp("^[ ]*@" + options.name + "さん");
      message = message.replace(name_re, options.name)
      user = @robot.brain.userForId userId
      @bot.room_id = room_id
      @receive new TextMessage user, message

    @bot.listen()
    @emit 'connected'

exports.use = (robot) ->
  new Devhub robot

class DevhubStreaming extends EventEmitter
  constructor: (options, @robot) ->
    @name = options.name
    client = require('socket.io-client');
    @socket = client.connect(options.url);
    @room_id = 1
    @avatar = "img/hubot.png"

  send: (message) ->
    @socket.emit "message", {name:@name, msg:message, room_id:@room_id, avatar:@avatar }

  listen: ->
    @socket.on "message", (item)=>
      @emit 'message', item.name, item.msg, item.room_id
    @socket.emit 'name', {name:@name, avatar:@avatar}

  reset_avatar: ->
    @socket.emit 'name', {name:@name, avatar:@avatar}
