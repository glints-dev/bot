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
#   show me the referral <refCode> in <id|sg>
#   show me the weekly stats of <id|sg>
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
treeify = require 'treeify'
conString_sg = process.env.HUBOT_PSQL_SG_STRING
conString_id = process.env.HUBOT_PSQL_ID_STRING

module.exports = (robot) ->
  robot.hear /show me the weekly stats of (sg|id)?/i, (res) ->
    channel = res.message.rawMessage.channel
    real_name = res.message.user.slack.profile.first_name
    country = res.match[1]
    if !country
      res.send "Dimwit, please indicate the country. `show me the weekly stats of <sg or id>`. But out of the kindness of my metal heart, I'm assuming Singapore."
      country = 'sg'
    switch country
      when 'sg'
        conString = conString_sg
      when 'id'
        conString = conString_id
      else 
        conString = conString_sg
    pg.connect conString, (err, client, done) ->
      if err
         return console.error 'Error fetching client from pool', err
      client.query 'SELECT * FROM weekly()', (err, result) ->
        done()
        if err
          return console.error 'Error running query', err
        weekly = result.rows
        fields = ['application_count', 'job_count', 'user_count', 'company_count', 'candidate_count', 'active_users', 'monday']
        json2csv {
          data: weekly,
          fields: fields
        }, (err, csv) ->
          if err
            throw err
          fileName = "weekly_for_#{country}.csv"
          fs.writeFile fileName, csv, (err) ->
            if err
              throw err
            filePath = path.join(__dirname, '..', fileName)
            slack.uploadFile {
              file: fs.createReadStream filePath
              filetype: 'csv'
              title: "To my illicit spouse #{real_name} :kissing_heart:"
              channels: channel
              initialComment: "Weekly stats for #{country}"
            }, (err) ->
              if err
                console.error err
              else
                fs.unlinkSync filePath
              return
            return
          return
                 
        
  robot.hear /show me the referral (\S+)(?: in (sg|id))?(?: from ((?:\d|\-)+) to ((?:\d|\-)+))?/i, (res) ->
    channel = res.message.rawMessage.channel
    real_name = res.message.user.slack.profile.first_name
    referral = res.match[1]
    country = res.match[2]
    startDate = res.match[3]
    endDate = res.match[4]
    if !country or !startDate or !endDate
      res.send ":japanese_ogre: Please indicate the country. `show me the referral <refCode> in <sg or id> from <isoDate> to <isoDate>`. But out of the kindness of my metal heart, I'm assuming Indonesia and forever"
      country = 'id'
      startDate = '01-01-2000'
      endDate = '01-01-3000'
    switch country
      when 'sg'
        conString = conString_sg
      when 'id'
        conString = conString_id
      else 
        conString = conString_id
    pg.connect conString, (err, client, done) ->
      if err
         return console.error 'Error fetching client from pool', err
      client.query 'SELECT email, referral, resume, CASE WHEN "emailVerificationToken" ISNULL THEN TRUE ELSE FALSE END as "isVerified", CASE WHEN e.type = \'EDUCATION\' THEN TRUE ELSE FALSE END AS "profile",CASE WHEN e.type = \'EDUCATION\' AND(e.institution ILIKE \'ui\' or e.institution ILIKE \'%Universitas Indonesia%\' or e.institution ILIKE \'University of Indonesia\') THEN TRUE ELSE FALSE END as "UI", CASE WHEN e.type = \'EDUCATION\' AND (e.institution ILIKE \'itb\' or e.institution ILIKE \'%Institut Teknologi Bandung%\' or e.institution ILIKE \'%Institute Technology of Bandung%\' or e.institution ILIKE \'%Bandung Institute of Technology%\' or e.institution ILIKE \'%Ganesha 10%\') THEN TRUE ELSE FALSE END AS "ITB" FROM "Users" as u LEFT JOIN "Experiences" as e on u.id = e."UserId" WHERE referral ILIKE $1 AND u."createdAt" >= $2 AND u."createdAt" <= $3;', [referral, startDate, endDate], (err, result) ->
        done()
        if err
          return console.error 'Error running query', err
        allUsers = result.rows
        total = allUsers.length
        if total == 0
            res.reply ":japanese_ogre: No users registered under this referral code!"
            return
        users = {
          verified: {
            self: [],
            CV: {
              self: [],
              profile: {
                self: [],
                UI: {
                  self: []
                  },
                ITB: {
                  self: []
                }
              }
            },
            noCV: {
              self: [],
              profile: {
                self: [],
                UI: {
                  self: []
                  },
                ITB: {
                  self: []
                }
              }
            }
            },
          unverified: {
            self: [],
            CV: {
              self: [],
              profile: {
                self: [],
                UI: {
                  self: []
                  },
                ITB: {
                  self: []
                }
              }
            },
            noCV: {
              self: [],
              profile: {
                self: [],
                UI: {
                  self: []
                  },
                ITB: {
                  self: []
                }
              }
            }
          }
        }
        users.verified.self = allUsers.filter((u) ->
          u.isVerified
        )

       # Verified with CV
        users.verified.CV.self = users.verified.self.filter((u) ->
          u.resume
        )
        users.verified.CV.profile.self = users.verified.CV.self.filter((u) ->
          u.profile
        )
        users.verified.CV.profile.UI.self = users.verified.CV.profile.self.filter((u) ->
          u.UI
        )
        users.verified.CV.profile.ITB.self = users.verified.CV.profile.self.filter((u) ->
          u.ITB
        )

        # Verified but no CV
        users.verified.noCV.self = users.verified.self.filter((u) ->
          !u.resume
        )
        users.verified.noCV.profile.self = users.verified.noCV.self.filter((u) ->
          u.profile
        )
        users.verified.noCV.profile.UI.self = users.verified.noCV.profile.self.filter((u) ->
          u.UI
        )
        users.verified.noCV.profile.ITB.self = users.verified.noCV.profile.self.filter((u) ->
          u.ITB
        )

        #  Unverified users
        users.unverified.self = allUsers.filter((u) ->
          !u.isVerified
        )

        # Unverified with CV
        users.unverified.CV.self = users.unverified.self.filter((u) ->
          u.resume
        )
        users.unverified.CV.profile.self = users.unverified.CV.self.filter((u) ->
          u.profile
        )
        users.unverified.CV.profile.UI.self = users.unverified.CV.profile.self.filter((u) ->
          u.UI
        )
        users.unverified.CV.profile.ITB.self = users.unverified.CV.profile.self.filter((u) ->
          u.ITB
        )

        # Unverified and no CV
        users.unverified.noCV.self = users.unverified.self.filter((u) ->
          !u.resume
        )
        users.unverified.noCV.profile.self = users.unverified.noCV.self.filter((u) ->
          u.profile
        )
        users.unverified.noCV.profile.UI.self = users.unverified.noCV.profile.self.filter((u) ->
          u.UI
        )
        users.unverified.noCV.profile.ITB.self = users.unverified.noCV.profile.self.filter((u) ->
          u.ITB
        )

        userCount = {
          total: total,
          verified: {
            number: users.verified.self.length,
            CV: {
              number: users.verified.CV.self.length,
              profile: {
                number: users.verified.CV.profile.self.length,
                UI: {
                  number: users.verified.CV.profile.UI.self.length
                }
                ITB: {
                  number: users.verified.CV.profile.ITB.self.length
                },
                others: {
                  number: users.verified.CV.profile.self.length - users.verified.CV.profile.UI.self.length - users.verified.CV.profile.ITB.self.length
                }
              },
              'no Profile': {
                number: users.verified.CV.self.length - users.verified.CV.profile.self.length
              }
            },
            'no CV': {
              number: users.verified.noCV.self.length,
              profile: {
                number: users.verified.noCV.profile.self.length,
                UI: {
                  number: users.verified.noCV.profile.UI.self.length
                },
                ITB: {
                  number: users.verified.noCV.profile.ITB.self.length
                },
                others: {
                  number: users.verified.noCV.profile.self.length - users.verified.noCV.profile.UI.self.length - users.verified.noCV.profile.ITB.self.length
                }
              },
              'no Profile': {
                number: users.verified.noCV.self.length - users.verified.noCV.profile.self.length
              }
            }  
          },
          unVerified: {
            number: users.unverified.self.length,
            CV: {
              number: users.unverified.CV.self.length,
              profile: {
                number: users.unverified.CV.profile.self.length,
                UI: {
                  number: users.unverified.CV.profile.UI.self.length
                }
                ITB: {
                  number: users.unverified.CV.profile.ITB.self.length
                },
                others: {
                  number: users.unverified.CV.profile.self.length - users.unverified.CV.profile.UI.self.length - users.unverified.CV.profile.ITB.self.length
                }
              },
              'no Profile': {
                number: users.unverified.CV.self.length - users.unverified.CV.profile.self.length
              }
            },
            'no CV': {
              number: users.unverified.noCV.self.length,
              profile: {
                number: users.unverified.noCV.profile.self.length,
                UI: {
                  number: users.unverified.noCV.profile.UI.self.length
                },
                ITB: {
                  number: users.unverified.noCV.profile.ITB.self.length
                },
                others: {
                  number: users.unverified.noCV.profile.self.length - users.unverified.noCV.profile.UI.self.length - users.unverified.noCV.profile.ITB.self.length
                }
              },
              'no Profile': {
                number: users.unverified.noCV.self.length - users.unverified.noCV.profile.self.length
              }
            }  
          }
        }
        fields = ['email', 'referral', 'resume', 'isVerified', 'Profile', 'UI', 'ITB']
        json2csv {
          data: allUsers,
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
              initialComment: "#{treeify.asTree(userCount, true)}"
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
