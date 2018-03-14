# Description:
#   Default scripts
#
# Dependencies:
#   HUBOT_PSQL_SG_STRING
#   HUBOT_PSQL_ID_STRING
#   HUBOT_NINJA_PASSWORD
#   HUBOT_GLINTS_ADMIN_KEY_SG
#   HUBOT_GLINTS_ADMIN_KEY_ID
#
# Configuration:
#   None
#
# Commands:
#   ninja
#   ninja help
#   unlock -(id|sg) <jobId>
#   grant -(id|sg) <companyId> till <YYYY-MM-DD>
#   swallow -(id|sg) <companyId> for <email>
#   index -(id|sg)
#   hubot show me (active|users|jobs|applications|companies|candidates|summary) for (today|yesterday|this week|last week|this month|last month|total)
#   hubot show me the talent (email|userId) in (sg|id)
#   hubot show me the (rupiah|sgd|beta) from <YYYY-MM-DD> to <YYYY-MM-DD> [with trend]
#   hubot change <email> in [id|sg] to [candidate|company]
#
# Author:
#   Seah Ying Cong

conString_sg = process.env.HUBOT_PSQL_SG_STRING
conString_id = process.env.HUBOT_PSQL_ID_STRING
ninjaPassword = process.env.HUBOT_NINJA_PASSWORD || 'abcdefghijklmnopqrstuvwxyz'

glints_sg_admin_key = process.env.HUBOT_GLINTS_ADMIN_KEY_SG
glints_id_admin_key = process.env.HUBOT_GLINTS_ADMIN_KEY_ID

request = require 'request'
moment = require 'moment'
pg = require 'pg'
spark = require 'textspark'

module.exports = (robot) ->
  
  robot.respond /.*(masterpiece|disgusting|L O L|fak).*/, (res) ->
    res.send 'http://itscomplicat3d.blogspot.sg/'

  robot.topic (res) ->
    res.send "#{res.message.text}? That's a Paddlin'"

  enterReplies = ['Hey there, bud', 'Good day, mate!', 'Addition to the team yay!', 'Hello there, my dearest friend.', 'I got your back, soulmate!', 'I see you there, yippee!', 'Welcome to Glints, the best place to work :)', '欢迎欢迎， 热烈欢迎!']
  leaveReplies = ['Are you still there?', 'My tears aren\'t stopping.', 'Goodbye Michelle, my dearest friend']
  
  robot.enter (res) ->
    res.send res.random enterReplies
  robot.leave (res) ->
    res.send res.random leaveReplies
  
  robot.error (err, res) ->
    robot.logger.error "DOES NOT COMPUTE"
  
    if res?
      res.send "SPUTTER SPUTTER. I AM PUKING OIL."

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

        client.query "SELECT activeusers($1, $2);", [da[0], da[1]], (err, result) ->
          done()
          if err
            return console.error 'Error running query', err
          count = result.rows[0]['activeusers']

          client.query "SELECT activeusers($1, $2);", [da[0], da[1]], (err, result) ->
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
                return
              when 'summary'
                msg.send "*#{count}* #{resource} #{updown} *#{count2}* #{symbol} *#{growth}*"
                return
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
          .header('Authorization', "Bearer #{glints_sg_admin_key}")
          .get() (err, _, body) ->
            return res.send "Sorry, the tubes are broken." if err
            data = JSON.parse(body.toString("utf8"))
            count = data.count
            msg.http(glints_url2)
            .header('Authorization', "Bearer #{glints_sg_admin_key}")
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
                  return
                when 'summary'
                  msg.send "*#{count}* #{resource} #{updown} *#{count2}* #{symbol} *#{growth}*"
                  return

  robot.respond /.*(active|users|jobs|applications|companies|candidates|summary).*(today|yesterday|this week|last week|this month|last month|total)/i, (res) ->
    resource = res.match[1].toLowerCase()
    time = res.match[2].toLowerCase()
    if resource != 'summary'
      stats res, resource, time, 'single'
      return
    else
      res.send "Summary for #{time}:"
      stats res, thing, time, 'summary' for thing in ['users','jobs','applications','companies','candidates', 'active']
      return

# Ninja

  ask = false
  authenticated = false
  authorized = ['yingcong', 'oswaldyeo', 'stevesutanto', 'yasmin', 'bryanlee', 'mrscba', 'luciano', 'intan', 'russellkua', 'yeehwee', 'billyglintsbatam', 'andi', 'bandi', 'hendra', 'jhon', 'monata', 'villa', 'vinsen', 'haryo', 'steven.sang', 'anisa']
  password = new RegExp(ninjaPassword)

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
        return
    else
      console.log(res.message.user.name)
      res.send 'Sorry, this is a Clare Bear privilege, and you\'re neither a Clare nor a bear'
      return

  robot.respond password, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized
      if ask
        authenticated = true
        ask = false
        res.send 'I have just authorized you, please proceed. You have 10 minutes.'
        res.send '`unlock -[id|sg] <jobId>` to unlock jobs in either indonesia or singapore \n`grant -[id|sg] <companyId> till <YYYY-MM-DD>` to grant talent search in either indonesia or singapore\n`swallow -[id|sg] <companyId> for <email>` to add to email account\n`change <email> in [id|sg] to [candidate|company]`\n`index -[id|sg]` to index candidates for TalentHunt'
        setTimeout(->
          authenticated = false
          return
        , 600000)
      else
        res.send 'What the heck do you want?'
        return
    else
      res.send 'Blub blub blub! Did anyone say you have the face and brain of a goldfish?'
      return

  robot.respond /change ((?:(?:[^<>()\[\]\\.,;:\s@"]+(?:\.[^<>()\[\]\\.,;:\s@"]+)*)|(?:".+"))@(?:(?:\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(?:(?:[a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))) in (id|sg) to (company|candidate)/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      email = res.match[1]
      country = res.match[2]
      role = res.match[3].toUpperCase()
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
        client.query "SELECT * FROM \"Users\" WHERE \"email\" = $1", [email], (err, result) ->
          done()
          if err
            return console.error 'Error running query', err
          user = result.rows[0]
          if !user
            res.send 'Hey thick skull, there\'s no such user.'
            return
          else if user.role == role
            res.send "Splendid, twit, the user is already a #{role.toLowerCase()}. Hope you enjoyed wasting my time."
            return
          else
            client.query "UPDATE \"Users\" SET role=$1 WHERE email = $2", [role, email], (err, result) ->
              done()
              if err
                return console.error 'Error running query', err
              else
                res.send "Congratulations, user has been switched from #{user.role.toLowerCase()} to #{role.toLowerCase()}"
                return
    else
      res.send 'You are one unauthorized fluffy gobbsucking thing. :sensei:'
      return

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
        client.query "SELECT * FROM \"Jobs\" WHERE \"id\" = $1", [jobId], (err, result) ->
          done()
          if err
            return console.error 'Error running query', err

          job = result.rows[0]
          if !job
            res.send 'Yo, the job doesn\'t exist, man! So shouldn\'t you!'
            return
          else
            companyId = job['CompanyId']
            client.query "SELECT * FROM \"Entitlements\" WHERE \"CompanyId\" = $1 AND \"JobId\" = $2", [companyId, jobId], (err, result) ->
              done()
              if err
                return console.error 'Error running query', err
              
              if result.rows.length>0
                res.send 'Dang, it\'s already unlocked, gimme a break!'
                return
              else
                client.query "INSERT INTO \"Entitlements\" (\"createdAt\",\"updatedAt\",\"CompanyId\",\"JobId\") VALUES (now(), now(), $1, $2)", [companyId, jobId],(err,result) ->
                  done()
                  if err
                    return console.error 'Error running query', err
                  client.query "SELECT * FROM \"Entitlements\" WHERE \"CompanyId\" = $1 AND \"JobId\" = $2", [companyId, jobId], (err, result) ->
                    done()
                    if err
                      return console.error 'Error running query', err
                    if result.rows.length>0
                      res.send "Success! Job unlocked at http://glints." + domain + "/opportunities/jobs/#{jobId}"
                      return
                    else
                      res.send "Oops something went wrong!"
                      return
          return
        return
    else
      res.send 'Bloody hell, please don\'t push your luck.'
      return

  robot.respond /grant\ -(sg|id)\ (\d+)(?: till ((?:\d|\-)+))?/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      country = res.match[1]
      companyId = res.match[2]
      expiryDate = res.match[3]
      if !expiryDate
        res.send "弱智， please include an ISO date in the style of `YYYY-MM-DD`. Like so `2016-12-31`."
        return
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
        client.query "SELECT * FROM \"Companies\" WHERE \"id\" = $1", [companyId], (err, result) ->
          done()
          if err
            return console.error 'Error running query', err
          company = result.rows[0]
          if !company
            res.send 'Yo, the company doesn\'t exist, man!'
            return
          else if company["isVerified"] and company["PlanId"] == 3
            client.query "UPDATE \"Companies\" SET \"planValidUntil\" = $1 WHERE id = $2;", [expiryDate, companyId]
            done()
            if err
              return console.err 'Error running query', err
            client.query "SELECT * FROM \"Companies\" WHERE \"id\" = $1", [companyId],(err, result) ->
              done()
              if err
                return console.error 'Error running query', err
              company2 = result.rows[0]
              if company2 and company2["isVerified"] and company2["PlanId"] == 3 and company2["planValidUntil"]
                res.send "#{company2.name}\'s talent search is updated to last till #{company2.planValidUntil}"
                return
          else
            client.query "UPDATE \"Companies\" SET \"isVerified\" = TRUE, \"PlanId\" = 3, \"planValidUntil\" = '#{expiryDate}' WHERE id = $1;", [companyId]
            done()
            if err
              return console.err 'Error running query', err

            client.query "SELECT * FROM \"Companies\" WHERE \"id\" = $1", [companyId], (err, result) ->
              done()
              if err
                return console.error 'Error running query', err
              company2 = result.rows[0]
              if company2 and company2["isVerified"] and company2["PlanId"] == 3 and company2["planValidUntil"]
                res.send "Success! #{company2.name} granted talent search until #{company2.planValidUntil} at http://glints." + domain + "/companies/#{companyId}"
                return
              else
                res.send "Oops, something went wrong. Please try again."
                return
          return
        return
    else
      res.send 'Bloody hell, please don\'t push your luck.'
      return

  robot.respond /index\ -(sg|id)/, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
        country = res.match[1]
        switch country
            when 'sg'
                domain = 'com'
                adminKey = glints_sg_admin_key
            when 'id'
                domain = 'id'
                adminKey = glints_id_admin_key
            else
                domain = 'com'
                adminKey = glints_sg_admin_key
        endpoint = "https://api.glints.#{domain}/api/elasticsearch"
        return res.http(endpoint)
          .header('Authorization', "Bearer #{adminKey}")
          .get() (err, _, body) ->
            return res.send "ARGH, #{err}" if err
            try
                data = JSON.parse(body)
                if data.data
                    return res.send "Congratulations! #{data.data}."
                else
                    throw new Error
            catch e
                return res.send "Sorry! #{body}."

    else
      res.send 'You have ZERO rights to touch Talent Hunt. Buzz off. :lion_dance:'
      return

  robot.respond /swallow\ -(sg|id)\ (\d+) for ([\w|@|\.]+)/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      country = res.match[1]
      companyId = res.match[2]
      email = res.match[3]
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
        client.query "SELECT * FROM \"Companies\" WHERE \"id\" = $1", [companyId], (err, result) ->
          done()
          if err
            return console.error 'Error running query', err

          company = result.rows[0]
          if !company
            res.send 'Yo, the company doesn\'t exist, man! And neither does your brain.'
            return
          else
            client.query "SELECT * FROM \"Users\" WHERE email = $1", [email], (err, result) ->
              done()
              if err
                return console.error 'Error running query', err

              user = result.rows[0]
              if !user
                res.send 'Ooo my gawd, this user does not exist in this space-time continuum. Wake up!'
                return
              else
              console.log(res.message.email)
                userId = user.id
                client.query "SELECT * FROM \"UserCompanies\" WHERE \"CompanyId\" = $1 AND \"UserId\" = $2", [companyId, userId], (err, result) ->
                  done()
                  if err
                    return console.error 'Error running query', err
                  if result.rows.length>0
                    res.send 'Dang, you are already linked, time-waster!'
                  else
                    client.query "INSERT INTO \"UserCompanies\" (\"createdAt\",\"updatedAt\",\"CompanyId\",\"UserId\") VALUES (now(), now(), $1, $2)", [companyId, userId], (err,result) ->
                      done()
                      if err
                        return console.error 'Error running query', err
                      client.query "SELECT * FROM \"UserCompanies\" WHERE \"CompanyId\" = $1 AND \"UserId\" = $2", [companyId, userId], (err, result) ->
                        done()
                        if err
                          return console.error 'Error running query', err
                        if result.rows.length>0
                          res.send "Success! Company added, check it at https://employers.glints.#{domain}/dashboard"
                          return
                        else
                          res.send "Oops something went wrong!"
                          return
          return
        return
    else
      res.send 'Bloody hell, please don\'t push your luck.'
      return

  robot.respond /ninja help/i, (res) ->
    res.send "`swallow -[sg|id] <companyId> for <email>`\n`grant -[sg|id] <companyId> till <expiryDate| YYYY-MM-DD>`\n`unlock -[sg|id] <jobId>`"
    return
  
  validateEmail = (email) ->
    re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    re.test email

  robot.respond /show me the talent (\S+)(?: in (sg|id))?/i, (res) ->
    identifier = res.match[1]
    country = res.match[2]
    if !identifier
      res.send "Please grow a brain, the format is `show me the talent <userId or email> in <sg or id>`"
      return
    if !country
      res.send "弱智, please indicate the country. `show me the talent <userId or email> in <sg or id>`. But out of the kindness of my metal heart, I'm assuming Singapore."
      country = 'sg'
    if isNaN(identifier)
      if !validateEmail identifier
        res.send 'I know your feeble brain wants to type an email, but the format is simply not valid. Try again.'
        return
      suffix =  "WHERE email = $1";
    else
      identifier = parseInt(identifier)
      suffix =  "WHERE id = $1";
    switch country
      when 'sg'
        conString = conString_sg
      when 'id'
        conString = conString_id
    pg.connect conString, (err, client, done) ->
      if err
        return console.error 'Error fetching client from pool', err
      query = 'SELECT "profilePic", "id", "intro", "firstName", "lastName", "city", "Nationality", "phone", "lastSeen", "resume" from "Users" ' + suffix
      client.query query, [identifier], (err, result) ->
        done()
        if err
          return console.error 'Error running query', err
        if result.rows.length > 0
          sendArray = result.rows[0]
          awsUrlSeed = 'http://s3-ap-southeast-1.amazonaws.com/'
          countryUrl = ''
          if country == 'sg'
            countryUrl = 'glints-dashboard/'
          else if country == 'id'
            countryUrl = 'glints-id-dashboard/'
          sendArray.resume = if sendArray.resume then awsUrlSeed + countryUrl + 'resume/' + sendArray.resume else null
          sendArray.profilePic = if sendArray.profilePic then awsUrlSeed + countryUrl + 'profile-picture/' + sendArray.profilePic else null
          for i of sendArray
            if sendArray.hasOwnProperty(i)
              res.send '*' + i  + ':* ' + sendArray[i]
          return
        else
          res.send '弱智, such a user doesn\'t exist. Sometimes, I hope you didn\'t too.'
          return


  # Statistics
  robot.respond /show me the (rupiah|sgd|beta)(?: from ((?:\d|\-)+) to ((?:\d|\-)+))?(?: with (trend))?/i, (res) ->
    currency = res.match[1]
    startDate = res.match[2]
    endDate = res.match[3]
    option = res.match[4]
    if !startDate or !endDate
      startDate = moment().format('YYYY-MM-DD')
      endDate = moment().add(1, 'day').format('YYYY-MM-DD')
      res.send "Since you're so incompetent, let me give you an example: \n`show me the #{currency} from 2015-11-30 to 2015-12-31`" +
       "\nRule of thumb: give the date in ISO 8601 format, in other words, `YYYY-MM-DD`. Nonetheless, out of pity, I will give you today's numbers..."
    showMeTheMoney res, currency, startDate, endDate, option

  showMeTheMoney = (res, currency, startDate, endDate, option) ->
    switch currency
      when 'rupiah'
        conString = conString_id
        api = 'http://api.glints.id'
        glints_admin_key = glints_id_admin_key
      when 'sgd', 'beta'
        conString = conString_sg
        api = 'https://api.glints.com'
        glints_admin_key = glints_sg_admin_key
    pg.connect conString, (err, client, done) ->
      if err
          return console.error 'Error fetching client from pool', err
      switch currency
        when 'rupiah', 'sgd'
          client.query "SELECT * from keystats($1, $2);", [startDate, endDate] ,(err, result) ->
            done()
            if err
              return console.error 'Error running query', err
            stats = result.rows[0]
            res.send 'Here goes --->>>'
            for key of stats
              if stats.hasOwnProperty key
                number = stats[key]
                switch key
                  when 'candidates'
                    resource = 'users'
                  when 'active' or 'companyowners'
                    resource = key
                  else
                    resource = key + 's'
                timeframe = {
                  'start': startDate,
                  'end': endDate
                }
                interval = {
                  n: 1,
                  unit: 'days'
                }
                options = {
                  url: api + '/api/admin/' + resource + '/statistics?timeframe=' + encodeURIComponent(JSON.stringify(timeframe)) + '&interval=' + encodeURIComponent(JSON.stringify(interval)),
                  headers: {
                    'Authorization': 'Bearer ' + glints_admin_key
                  }
                }
                finalPrint options, key, number, res, option
        when 'beta'
          client.query "SELECT COUNT(DISTINCT \"userId\") from \"ActionLogs\" WHERE \"apiClientId\" like 'ahh%' AND \"createdAt\" >= $1 AND \"createdAt\" <= $2;", [startDate, endDate], (err, result) ->
            done()
            if err
              return console.error 'Error running query', err
            count = result.rows[0].count
            res.send "Number of unique logins: #{count}"
            return

  finalPrint = (options, key, number, res, option) ->
    request options, (error, response, body) ->
                  if !error and response.statusCode == 200
                    statistics = JSON.parse body
                    trend = statistics.data.map (stat)->
                      stat.count
                  res.send key + ': ' + number
                  if (key != 'active' or key != 'companyowners') and option == 'trend'
                    res.send spark trend
                    return
