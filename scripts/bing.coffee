# Description:
#   Queries Bing and returns a random image from the top 50 images found using Bing API
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_BING_ACCOUNT_KEY
#
# Commands:
#   hubot image <query> - Queries Bing Images for <query> & returns a random result from top 50
#
# Author:
#   Brandon Satrom

bingAccountKey = process.env.HUBOT_BING_ACCOUNT_KEY

module.exports = (robot) ->
  robot.hear /image (.+)/i, (msg) ->
    imageMe msg, msg.match[1], (url) ->
      msg.send url

imageMe = (msg, query, cb) ->
  msg.http('https://api.datamarket.azure.com/Bing/Search/Image')
    .header("Authorization", "Basic " + new Buffer("#{bingAccountKey}:#{bingAccountKey}").toString('base64'))
    .query(Query: "'" + query + "'", $format: "json", $top: 50)
    .get() (err, res, body) ->
      try
        images = JSON.parse(body).d.results
        image = msg.random images
        cb image.MediaUrl
      catch error
        cb body