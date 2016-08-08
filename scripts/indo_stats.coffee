# Description:
#   Slack File Upload
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_PSQL_SG_STRING
#   HUBOT_PSQL_ID_STRING
#
# Commands:
#   show me the applicants for job <id>
#   show me the referral <refCode> in <id|sg>
#
# Author:
#   Ying Cong

pg = require 'pg'
conString_id = process.env.HUBOT_PSQL_ID_STRING

module.exports = (robot) ->
    robot.respond /show me the [ITB|UI]/i, (res) ->
        pg.connect conString_id, (err, client, done) ->
            if err
                return console.error 'Error connecting to database', err
            client.query 'SELECT (SELECT count(*) FROM \"Users\" as u, \"Experiences\" as e WHERE e.\"UserId\" = u.id AND e.type = \'EDUCATION\' AND (e.institution ILIKE \'ui\' or e.institution ILIKE \'%Universitas Indonesia%\' or e.institution ILIKE \'University of Indonesia\')) AS \"UI\", (SELECT count(*) FROM \"Users\" as u, \"Experiences\" as e WHERE e.\"UserId\" = u.id AND e.type = \'EDUCATION\' AND (e.institution ILIKE \'itb\' or e.institution ILIKE \'%Institut Teknologi Bandung%\' or e.institution ILIKE \'%Institute Technology of Bandung%\' or e.institution ILIKE \'%Bandung Institute of Technology%\' or e.institution ILIKE \'%Ganesha 10%\')) AS \"ITB\"', (err, result) ->
                done()
                if err
                    return console.error 'Error running query', err
                count = result.rows[0]
                res.send "UI: #{count.UI}\nITB: #{count.ITB}"
                return
