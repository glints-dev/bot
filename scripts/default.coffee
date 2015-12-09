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

conString_sg = process.env.HUBOT_PSQL_SG_STRING
conString_id = process.env.HUBOT_PSQL_ID_STRING


glints_admin_key = process.env.HUBOT_GLINTS_ADMIN_KEY
moment = require 'moment'
pg = require 'pg'

module.exports = (robot) ->

  ROOM = process.env.HUBOT_STARTUP_ROOM ? 'pleasure-pavilion'
  MESSAGE = process.env.HUBOT_STARTUP_MESSAGE ? 'Hello, cruel world!'
  # robot.messageRoom ROOM, MESSAGE

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
  
  robot.respond /.*(masterpiece|disgusting|L O L|fak).*/, (res) ->
    res.send 'http://itscomplicat3d.blogspot.sg/'

  robot.topic (res) ->
    res.send "#{res.message.text}? That's a Paddlin'"

  enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  
  robot.enter (res) ->
    res.send res.random enterReplies
  robot.leave (res) ->
    res.send res.random leaveReplies
  
  answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  
  robot.respond /question of life/, (res) ->
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
      res.send "SPUTTER SPUTTER"
  
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

  robot.respond /.*(active|users|jobs|applications|companies|candidates|summary).*(today|yesterday|this week|last week|this month|last month|total)/i, (res) ->
    resource = res.match[1].toLowerCase()
    time = res.match[2].toLowerCase()
    if resource != 'summary'
      stats res, resource, time, 'single'
    else
      res.send "Summary for #{time}:"
      stats res, thing, time, 'summary' for thing in ['users','jobs','applications','companies','candidates', 'active']

  stats = (msg, resource, time, mode) ->
    res = resource
    whereClause = 'where='
    where = {}
    where2 = {}
    switch time.toLowerCase()
      when 'today'
        start = moment()
        startX = moment().subtract(1,'d')
      when 'yesterday'
        start = moment().subtract(1,'d')
        end = moment()
        startX = moment().subtract(2,'d')
      when 'this week'
        start = moment().startOf('week')
        startX = moment().startOf('week').subtract(1,'w')
      when 'last week'
        start = moment().startOf('week').subtract(1, 'w')
        end = moment().startOf('week')
        startX = moment().startOf('week').subtract(2, 'w')
      when 'this month'
        start = moment().startOf('month')
        startX = moment().startOf('month').subtract(1, 'M')
      when 'last month'
        start = moment().startOf('month').subtract(1, 'M')
        end = moment().startOf('month')
        startX = moment().startOf('month').subtract(2, 'M')

    if !end
      end = moment().add(1, 'd')
    dates = [start, end, startX]

    da = (d.hour(0).minute(0).format('MM/DD/YYYY HH:mm') for d in dates when !!d)

    where['createdAt'] = {'gt': start} if !!start
    where['createdAt'] = where['createdAt'] || {}
    where['createdAt']['lt'] = end if !!end
    where2['createdAt'] = where2['createdAt'] || {}
    where2['createdAt'] = {'gt': startX} if !!startX
    where2['createdAt']['lt'] = start if !!start

    if res == 'active'
      resource = 'active users'
      pg.connect conString_sg, (err, client, done) ->
        if err
          return console.error 'Error fetching client from pool', err

        client.query "SELECT activeusers('#{da[0]}', '#{da[1]}');", (err, result) ->
          done()
          if err
            return console.error 'Error running query', err
          count = result.rows[0]['activeusers']

          client.query "SELECT activeusers('#{da[2]}', '#{da[0]}');", (err, result) ->
            done()
            if err
              return console.error 'Error running query', err

            count2 = result.rows[0]['activeusers']

            diff = count - count2
            updown = if diff>0 then 'up from' else if diff<0 then 'down from' else 'unchanged from'
            growth = ((diff/count2) * 100).toFixed(2) + ' %'
            symbol = if diff>0 then ':thumbsup:' else if diff<0 then ':small_red_triangle_down:' else ':fist:'
            
            switch mode
              when 'single'
                msg.send "Glints has *#{count}* #{resource} #{time} #{updown} *#{count2}* #{symbol} *#{growth}*"
              when 'summary'
                msg.send "*#{count}* #{resource} #{updown} *#{count2}* #{symbol} *#{growth}*"
    else
        if res == 'candidates' or res == 'companies'
          switch res
            when 'candidates'
              translated = 'candidate'
            when 'companies'
              translated = 'company'

          where['preferences'] = {'profileMode': translated }
          where2['preferences'] = {'profileMode': translated }
          res = 'users'

        glints_url = 'https://api.glints.com/api/admin/' + res + '?limit=1&where=' + JSON.stringify(where)
        glints_url2 = 'https://api.glints.com/api/admin/' + res + '?limit=1&where=' + JSON.stringify(where2)

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
              symbol = if diff>0 then ':thumbsup:' else if diff<0 then ':small_red_triangle_down:' else ':fist:'
              switch mode
                when 'single'
                  msg.send "Glints has *#{count}* #{resource} #{time} #{updown} *#{count2}* #{symbol} *#{growth}*"
                when 'summary'
                  msg.send "*#{count}* #{resource} #{updown} *#{count2}* #{symbol} *#{growth}*"

  ask = false
  authenticated = false
  authorized = ['yingcong', 'clarechai', 'qinen']
  password = new RegExp /clarebearcares/

  robot.respond /ninja/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized
      if !authenticated
        ask = true
        res.send 'Please enter password within the next minute:'
        setTimeout(->
          ask = false
          return
        , 60000)
      else
        res.send 'Already authorized, please proceed.'
    else
      res.send 'Sorry, this is a Clare Bear privilege, and you\'re neither a Clare nor a bear'

  robot.respond password, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized
      if ask
        authenticated = true
        ask = false
        res.send 'I have just authorized you, please proceed. You have 10 minutes.'
        res.send '`unlock -(id|sg) <jobId>` to unlock jobs in either indonesia or singapore \n`grant -(id|sg) <companyId>` to grant talent search in either indonesia or singapore\n`swallow -(id|sg) <companyId>` to add to ops@glints.com'
        setTimeout(->
          ask = false
          return
        , 600000)
      else
        res.send 'What the heck do you want?'
    else
      res.send 'hahaha!'


  robot.respond /unlock\ -(sg|id)\ (\d+)/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      country = res.match[1]
      jobId = res.match[2]
      switch country
        when 'sg'
          conString = conString_sg
          domain = 'com'
        when 'id'
          conString = conString_id
          domain = 'id'
        else 
          conString = conString_sg
      pg.connect conString, (err, client, done) ->
        if err
          return console.error 'Error fetching client from pool', err
        client.query "SELECT * FROM \"Jobs\" WHERE \"id\" = #{jobId}", (err, result) ->
          done()
          if err
            return console.error 'Error running query', err

          job = result.rows[0]
          if !job
            res.send 'Yo, the job doesn\'t exist, man!'
          else
            companyId = job['CompanyId']
            client.query "SELECT * FROM \"Entitlements\" WHERE \"CompanyId\" = #{companyId} AND \"JobId\" = #{jobId}", (err, result) ->
              done()
              if err
                return console.error 'Error running query', err
              
              if result.rows.length>0
                res.send 'Dang, it\'s already unlocked, gimme a break!'
              else
                client.query "INSERT INTO \"Entitlements\" (\"createdAt\",\"updatedAt\",\"CompanyId\",\"JobId\") VALUES (now(), now(), #{companyId}, #{jobId})", (err,result) ->
                  done()
                  if err
                    return console.error 'Error running query', err

                  client.query "SELECT * FROM \"Entitlements\" WHERE \"CompanyId\" = #{companyId} AND \"JobId\" = #{jobId}", (err, result) ->
                    done()
                    if err
                      return console.error 'Error running query', err
                    if result.rows.length>0
                      res.send "Success! Job unlocked at http://glints.' + domain + '/dashboard/jobs/#{jobId}"
                    else
                      res.send "Oops something went wrong!"
          return
        return
    else
      res.send 'Bloody hell, please don\'t push your luck.'


  robot.respond /grant\ -(sg|id)\ (\d+)/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      country = res.match[1]
      companyId = res.match[2]
      switch country
        when 'sg'
          conString = conString_sg
          domain = 'com'
        when 'id'
          conString = conString_id
          domain = 'id'
        else 
          conString = conString_sg
      pg.connect conString, (err, client, done) ->
        if err
          return console.error 'Error fetching client from pool', err
        client.query "SELECT * FROM \"Companies\" WHERE \"id\" = #{companyId}", (err, result) ->
          done()
          if err
            return console.error 'Error running query', err

          company = result.rows[0]
          if !company
            res.send 'Yo, the company doesn\'t exist, man!'
          else if company["isVerified"] and company["PlanId"] == 3
            res.send 'You\'re wasting my time, this company is already on talent search!'
          else
            client.query "UPDATE \"Companies\" SET \"isVerified\" = TRUE, \"PlanId\" = 3 WHERE id = #{companyId};"
            done()
            if err
              return console.err 'Error running query', err

            client.query "SELECT * FROM \"Companies\" WHERE \"id\" = #{companyId}", (err, result) ->
              done()
              if err
                return console.error 'Error running query', err

              company2 = result.rows[0]
              if company2 and company2["isVerified"] and company2["PlanId"] == 3
                res.send "Success! Company granted talent search at http://glints.' + domain + '/dashboard/companies/#{companyId}"
          return
        return
    else
      res.send 'Bloody hell, please don\'t push your luck.'

  robot.respond /swallow\ -(sg|id)\ (\d+)/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      country = res.match[1]
      companyId = res.match[2]
      switch country
        when 'sg'
          conString = conString_sg
          domain = 'com'
          userId = 12112
        when 'id'
          conString = conString_id
          domain = 'id'
          userId = 20528
        else 
          conString = conString_sg
      pg.connect conString, (err, client, done) ->
        if err
          return console.error 'Error fetching client from pool', err
        client.query "SELECT * FROM \"Companies\" WHERE \"id\" = #{companyId}", (err, result) ->
          done()
          if err
            return console.error 'Error running query', err

          company = result.rows[0]
          if !company
            res.send 'Yo, the company doesn\'t exist, man!'
          else
            client.query "SELECT * FROM \"UserCompanies\" WHERE \"CompanyId\" = #{companyId} AND \"UserId\" = #{userId}", (err, result) ->
              done()
              if err
                return console.error 'Error running query', err
              
              if result.rows.length>0
                res.send 'Dang, you are already linked, time-waster!'
              else
                client.query "INSERT INTO \"UserCompanies\" (\"createdAt\",\"updatedAt\",\"CompanyId\",\"UserId\") VALUES (now(), now(), #{companyId}, #{userId})", (err,result) ->
                  done()
                  if err
                    return console.error 'Error running query', err

                  client.query "SELECT * FROM \"UserCompanies\" WHERE \"CompanyId\" = #{companyId} AND \"UserId\" = #{userId}", (err, result) ->
                    done()
                    if err
                      return console.error 'Error running query', err
                    if result.rows.length>0
                      res.send "Success! Company added at http://glints.' + domain + '/dashboard/companies/#{companyId}"
                    else
                      res.send "Oops something went wrong!"
          return
        return
    else
      res.send 'Bloody hell, please don\'t push your luck.'