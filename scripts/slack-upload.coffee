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

module.exports = (robot) ->
  robot.hear /show me the applicants for job (\d+)/i, (res) ->
    real_name = res.message.user.real_name
    channel = res.message.rawMessage.channel
    jobId = res.match[1]
    pg.connect conString_sg, (err, client, done) ->
      if err
          return console.error 'Error fetching client from pool', err
      query = "SELECT \"firstName\", \"lastName\", \"email\", \"status\", \"resume\", \"A\".\"createdAt\" as \"ApplicationDate\" FROM \"Applications\" AS \"A\", \"Users\" AS \"U\", \"CandidateProfiles\" AS \"C\" WHERE \"A\".\"ApplicantId\" = \"U\".id  and \"A\".\"ApplicantProfileId\" = \"C\".\"id\" and \"JobId\" = #{jobId};"
      client.query query, (err, result) ->
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
              title: "To #{real_name} with :heart: but you still owe me :beer:",
              intial_comment: 'XOXO :heart: :heart:',
              channels: channel
            }, (err) ->
              if err
                console.error err
              else
                fs.unlinkSync filePath
              return
            return
          return