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
#   swallow <companyId> for <email>
#   index talenthunt
#   hubot show me the talent (email|userId)
#   hubot change <email> to [candidate|company]
#
# Author:
#   Seah Ying Cong

conString = process.env.HUBOT_PSQL_SG_STRING
ninjaPassword = process.env.HUBOT_NINJA_PASSWORD || 'abcdefghijklmnopqrstuvwxyz'

adminKey = process.env.HUBOT_GLINTS_ADMIN_KEY_SG

request = require 'request'
moment = require 'moment'
pg = require 'pg'
spark = require 'textspark'

module.exports = (robot) ->

# Ninja

  ask = false
  authenticated = false
  authorized = ['yingcong', 'oswaldyeo', 'stevesutanto', 'yasmin', 'bryanlee', 'mrscba', 'luciano', 'intan', 'russellkua', 'yeehwee', 'billyglintsbatam', 'andi', 'bandi', 'hendra', 'jhon', 'monata', 'villa', 'vinsen', 'haryo', 'steven.sang', 'anisa', 'freddydarmanto','hazelteng', 'fadil', 'xueli']
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
        res.send '`swallow <companyId> for <email>` to add to email account\n`change <email> to [candidate|company]`\n`index talenthunt` to index candidates for TalentHunt'
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

  robot.respond /change ((?:(?:[^<>()\[\]\\.,;:\s@"]+(?:\.[^<>()\[\]\\.,;:\s@"]+)*)|(?:".+"))@(?:(?:\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(?:(?:[a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))) to (company|candidate)/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      email = res.match[1]
      role = res.match[2].toUpperCase()
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
      res.send 'You are one unauthorized fluffy gob-sucking chunk of flesh. :sensei:'
      return

  robot.respond /index\ talenthunt/, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
        endpoint = "https://api.glints.com/api/elasticsearch"
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

  robot.respond /swallow\ ([a-zA-Z0-9-]+)\ for\ ([\w|\-|\+|@|\.]+)/i, (res) ->
    if res.message.user.name in authorized and res.message.user.room in authorized and !!authenticated
      companyId = res.match[1]
      email = res.match[2]
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
                          res.send "Success! Company added, check it at https://employers.glints.com/dashboard"
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


  robot.respond /show me the talent (\S+)/i, (res) ->
    identifier = res.match[1]
    if !identifier
      res.send "Please grow a brain, the format is `show me the talent <userId or email> in <sg or id>`"
      return
    if isNaN(identifier)
      if !validateEmail identifier
        res.send 'I know your feeble brain wants to type an email, but the format is simply not valid. Try again.'
        return
      suffix =  "WHERE email = $1";
    else
      identifier = parseInt(identifier)
      suffix =  "WHERE id = $1";
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
          countryUrl = 'glints-dashboard/'
          sendArray.resume = if sendArray.resume then awsUrlSeed + countryUrl + 'resume/' + sendArray.resume else null
          sendArray.profilePic = if sendArray.profilePic then awsUrlSeed + countryUrl + 'profile-picture/' + sendArray.profilePic else null
          for i of sendArray
            if sendArray.hasOwnProperty(i)
              res.send '*' + i  + ':* ' + sendArray[i]
          return
        else
          res.send '弱智, such a user doesn\'t exist. Sometimes, I hope you didn\'t too.'
          return
