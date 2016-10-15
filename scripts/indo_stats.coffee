# Description:
#   Slack File Upload
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_PSQL_ID_STRING
#
# Commands:
#   show me the <itb|ui>
#
# Author:
#   Ying Cong

pg = require 'pg'
conString_id = process.env.HUBOT_PSQL_ID_STRING

module.exports = (robot) ->
    robot.respond /show me the (?:ITB|UI)(?: from ((?:\d|\-)+) to ((?:\d|\-)+))?/i, (res) ->
        startDate = res.match[1]
        endDate = res.match[2]
        if !startDate or !endDate
            res.send ":japanese_ogre: show me the [ITB|UI] from <YYYY-MM-DD> to <YYYY-MM-DD>. But I'll assume forever."
            startDate = '01-01-2000'
            endDate = '01-01-3000'
        pg.connect conString_id, (err, client, done) ->
            if err
                return console.error 'Error connecting to database', err
            client.query 'SELECT (SELECT count(*) FROM \"Users\" as u, \"Experiences\" as e WHERE u.\"createdAt\" >= $1 AND u.\"createdAt\" <= $2 AND e.\"UserId\" = u.id AND e.type = \'EDUCATION\' AND (e.institution ILIKE \'ui\' or e.institution ILIKE \'%Universitas Indonesia%\' or e.institution ILIKE \'University of Indonesia\')) AS \"UI\", (SELECT count(*) FROM \"Users\" as u, \"Experiences\" as e WHERE u.\"createdAt\" >= $1 AND u.\"createdAt\" <= $2 AND e.\"UserId\" = u.id AND e.type = \'EDUCATION\' AND (e.institution ILIKE \'itb\' or e.institution ILIKE \'%Institut Teknologi Bandung%\' or e.institution ILIKE \'%Institute Technology of Bandung%\' or e.institution ILIKE \'%Bandung Institute of Technology%\' or e.institution ILIKE \'%Ganesha 10%\')) AS \"ITB\"', [startDate, endDate], (err, result) ->
                done()
                if err
                    return console.error 'Error running query', err
                count = result.rows[0]
                total = parseInt(count.ITB) + parseInt(count.UI)
                res.send "UI: #{count.UI}\nITB: #{count.ITB}\nTotal: #{total}"
                return
