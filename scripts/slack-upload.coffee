# Description:
#   Slack File Upload
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SLACK_TOKEN
#
# Commands:
#   show me the applicants for job <id>
#
# Author:
#   Ying Cong

slackToken = process.env.HUBOT_SLACK_TOKEN
Slack = require 'node-slack-upload'
slack = new Slack slackToken
pg = require 'pg'
json2csv = require 'json2csv'
fs = require 'fs'
path = require 'path'
conString_sg = process.env.HUBOT_PSQL_SG_STRING
conString_id = process.env.HUBOT_PSQL_ID_STRING

module.exports = (robot) ->
  robot.hear /show me the referral (\S+)(?: in (sg|id))?/i, (res) ->
    channel = res.message.rawMessage.channel
    real_name = res.message.user.slack.profile.first_name
    referral = res.match[1]
    country = res.match[2]
    if !country
      res.send "Bodoh, please indicate the country. `show me the referral <refCode> in <sg or id>`. But out of the kindness of my metal heart, I'm assuming Indonesia."
      country = 'id'
    switch country
        when 'sg'
          conString = conString_sg
          domain = 'com'
        when 'id'
          conString = conString_id
          domain = 'id'
        else 
          conString = conString_id
    pg.connect conString_id, (err, client, done) ->
      if err
         return console.error 'Error fetching client from pool', err
      client.query 'SELECT email, referral, resume, CASE WHEN "emailVerificationToken" ISNULL THEN TRUE ELSE FALSE END as "isVerified" FROM "Users" WHERE referral = $1', [referral], (err, result) ->
        done()
        if err
          return console.error 'Error running query', err
        users = result.rows
        total = users.length
        if total == 0
            res.reply "Bodoh, no users registered under this referral code! :japanese_ogre:"
            return
        isVerified = users.filter((u) ->
          u.isVerified
        ).length
        resume = users.filter((u) ->
            u.resume
        ).length
        fields = ['email', 'referral', 'resume', 'isVerified']
        json2csv {
          data: users,
          fields: fields
        }, (err, csv) ->
          if err
            throw err
          fileName = "ref#{referral}.csv"
          fs.writeFile fileName, csv, (err) ->
            if err
              throw err
            filePath = path.join(__dirname, '..', fileName)
            slack.uploadFile {
              file: fs.createReadStream filePath
              filetype: 'csv'
              title: "To my sweetheart #{real_name} :kissing_heart:"
              initialComment: "Out of #{total} user(s), #{isVerified} are/is verified and #{resume} have/has resume(s)"
              channels: channel
            }, (err) ->
              if err
                console.error err
              else
                fs.unlinkSync filePath
              return
            return
          return

  robot.hear /show me the applicants for job (\d+)/i, (res) ->
    real_name = res.message.user.slack.profile.first_name
    channel = res.message.rawMessage.channel
    jobId = res.match[1]
    pg.connect conString_sg, (err, client, done) ->
      if err
          return console.error 'Error fetching client from pool', err
      client.query "SELECT \"firstName\", \"lastName\", \"email\", \"status\", \"U\". \"resume\", \"A\".\"createdAt\" as \"ApplicationDate\" FROM \"Applications\" AS \"A\", \"Users\" AS \"U\", \"Profiles\" AS \"C\" WHERE \"A\".\"ApplicantId\" = \"U\".id  and \"A\".\"ApplicantProfileId\" = \"C\".\"id\" and \"JobId\" = $1;", [jobId] ,(err, result) ->
        done()
        if err
          return console.error 'Error running query', err
        applicants = result.rows
        applicants = applicants.map (applicant) ->
          applicant.resume = 'http://s3-ap-southeast-1.amazonaws.com/glints-dashboard/resume/' + applicant.resume
          applicant
        fields = ['firstName', 'lastName', 'email', 'status', 'resume', 'ApplicationDate']
        json2csv {
          data: applicants
          fields: fields
        }, (err, csv) ->
          if err
            throw err
          fileName = "job#{jobId}_applicants.csv"
          fs.writeFile fileName, csv, (err) ->
            if err
              throw err
            filePath = path.join(__dirname, '..', fileName)
            slack.uploadFile {
              file: fs.createReadStream filePath
              filetype: 'csv'
              title: "To #{real_name} with :heart: but you still owe me :beer:"
              initialComment: 'XOXO :heart: :heart:'
              channels: channel
            }, (err) ->
              if err
                console.error err
              else
                fs.unlinkSync filePath
              return
            return
          return
