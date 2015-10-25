# Description:
#   Example scripts for you to examine and try out.
#
# Configuration:
#   HUBOT_GLINTS_ADMIN_KEY
#   
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

glints_admin_key = process.env.HUBOT_GLINTS_ADMIN_KEY
moment = require 'moment'

module.exports = (robot) ->

  robot.hear /badger/i, (res) ->
    res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  
  robot.respond /open the (.*) doors/i, (res) ->
    doorType = res.match[1]
    if doorType is "pod bay"
      res.reply "I'm afraid I can't let you do that."
    else
      res.reply "Opening #{doorType} doors"
  
  robot.hear /I like pie/i, (res) ->
    res.emote "makes a freshly baked pie"
  
  lulz = ['lulz', 'rofl', 'lmao', ':satisfied:']
  
  robot.respond /(lol|haha)/i, (res) ->
    res.send res.random lulz
  
  robot.respond /.*(masterpiece|disgusting|L O L).*/, (res) ->
    res.send 'http://itscomplicat3d.blogspot.sg/'

  robot.topic (res) ->
    res.send "#{res.message.text}? That's a Paddlin'"
  
  robot.respond /.*(users|jobs|applications|companies|candidates|summary).*(today|yesterday|this week|last week|this month|last month|total)/i, (res) ->
    resource = res.match[1].toLowerCase()
    time = res.match[2].toLowerCase()
    if resource != 'summary'
      stats res, resource, time, 'single'
    else
      res.reply "Summary for #{time}:"
      stats res, thing, time, 'summary' for thing in ['users','jobs','applications','companies','candidates']

  stats = (msg, resource, time, mode) ->
    res = resource
    whereClause = 'where='
    where = {}
    where2 = {}
    switch time.toLowerCase()
      when 'today'
        start = moment().format('L')
        startX = moment().subtract(1,'d').format('L')
      when 'yesterday'
        start = moment().subtract(1,'d').format('L')
        end = moment().format('L')
        startX = moment().subtract(2,'d').format('L')
      when 'this week'
        start = moment().startOf('week').format('L')
        startX = moment().startOf('week').subtract(1,'w').format('L')
      when 'last week'
        start = moment().startOf('week').subtract(1, 'w').format('L')
        end = moment().startOf('week').format('L')
        startX = moment().startOf('week').subtract(2, 'w').format('L')
      when 'this month'
        start = moment().startOf('month').format('L')
        startX = moment().startOf('month').subtract(1, 'M').format('L')
      when 'last month'
        start = moment().startOf('month').subtract(1, 'M').format('L')
        end = moment().startOf('month').format('L')
        startX = moment().startOf('month').subtract(2, 'M').format('L')

    where['createdAt'] = {'gt': start} if !!start
    where['createdAt']['lt'] = end if !!end
    where2['createdAt'] = {'gt': startX} if !!startX
    where2['createdAt']['lt'] = start if !!start

    if res == 'candidates' or res == 'companies'
      switch res
        when 'candidates'
          translated = 'candidate'
        when 'companies'
          translated = 'company'

      where['preferences'] = {'profileMode': translated } 
      res = 'users'

    glints_url = 'https://api.glints.com/api/admin/' + res + '?limit=1&where=' + JSON.stringify(where)
    glints_url2 = 'https://api.glints.com/api/admin/' + res + '?limit=1&where=' + JSON.stringify(where2)
    console.log glints_url2

    msg.http(glints_url)
      .header('Authorization', 'Bearer hSXhkG0HYbMLVQ0rzjIxugTlLKIeCXIRH7YYPxJuXPkpoVxndOPycREI7Kh5mXToicjJKQNBVGUBwokyRxvVD0rL8HTasBHw9aqS7eOeyjjSd3NsjFf1EpkdoCSXPKob6FodK7Kn9anZe1d0lVplDGmczRImqtsczVfsV0YmxALjjzMBHJcuFgYmfVFDDdsLXkIXP5NTvCVQTsG9NvCbaBdZTRXaLEFMGFfG6x9RoIGjo9fZDxZrjuYSHMJWA9He')
      .get() (err, _, body) ->
        return res.send "Sorry, the tubes are broken." if err
        data = JSON.parse(body.toString("utf8"))
        count = data.count
        msg.http(glints_url2)
        .header('Authorization', 'Bearer hSXhkG0HYbMLVQ0rzjIxugTlLKIeCXIRH7YYPxJuXPkpoVxndOPycREI7Kh5mXToicjJKQNBVGUBwokyRxvVD0rL8HTasBHw9aqS7eOeyjjSd3NsjFf1EpkdoCSXPKob6FodK7Kn9anZe1d0lVplDGmczRImqtsczVfsV0YmxALjjzMBHJcuFgYmfVFDDdsLXkIXP5NTvCVQTsG9NvCbaBdZTRXaLEFMGFfG6x9RoIGjo9fZDxZrjuYSHMJWA9He')
        .get() (err, _, body) ->
          return res.send "Sorry, the tubes are broken." if err
          data2 = JSON.parse(body.toString("utf8"))
          count2 = data2.count
          diff = count - count2
          updown = if diff>0 then 'up from' else if diff<0 then 'down from' else 'unchanged from'
          growth = ((diff/count2) * 100).toFixed(2) + ' %'
          symbol = if diff>0 then ':thumbsup::skin-tone-2:' else if diff<0 then ':thumbsdown::skin-tone-6:' else ':fist:'
          switch mode
            when 'single'
              msg.reply "Glints has #{count} #{resource} #{time} #{updown} #{count2} #{symbol} #{growth}" 
            when 'summary'
              msg.send "#{count} #{resource} #{updown} #{count2} #{symbol} #{growth}" 

  enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  
  robot.enter (res) ->
    res.send res.random enterReplies
  robot.leave (res) ->
    res.send res.random leaveReplies
  
  answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  
  robot.respond /what is the answer to the ultimate question of life/, (res) ->
    unless answer?
      res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
      return
    res.send "#{answer}, but what is the question?"
  
  robot.respond /you(.*)slow/, (res) ->
    setTimeout () ->
      res.send "Who you calling 'slow'?"
    , 60 * 1000
  
  annoyIntervalId = null
  
  robot.respond /annoy me/, (res) ->
    if annoyIntervalId
      res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
      return
  
    res.send "Hey, want to hear the most annoying sound in the world?"
    annoyIntervalId = setInterval () ->
      res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
    , 1000
  
  robot.respond /unannoy me/, (res) ->
    if annoyIntervalId
      res.send "GUYS, GUYS, GUYS!"
      clearInterval(annoyIntervalId)
      annoyIntervalId = null
    else
      res.send "Not annoying you right now, am I?"
  
  
  robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
    room   = req.params.room
    data   = JSON.parse req.body.payload
    secret = data.secret
  
    robot.messageRoom room, "I have a secret: #{secret}"
  
    res.send 'OK'
  
  robot.error (err, res) ->
    robot.logger.error "DOES NOT COMPUTE"
  
    if res?
      res.reply "SPUTTER SPUTTER"
  
  robot.respond /have a soda/i, (res) ->
    # Get number of sodas had (coerced to a number).
    sodasHad = robot.brain.get('totalSodas') * 1 or 0
  
    if sodasHad > 4
      res.reply "I'm too fizzy.."
  
    else
      res.reply 'Sure!'
  
      robot.brain.set 'totalSodas', sodasHad+1
  
  robot.respond /sleep it off/i, (res) ->
    robot.brain.set 'totalSodas', 0
    res.reply 'zzzzz'
