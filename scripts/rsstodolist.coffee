# Description:
#   Allows you to send links to the RssToDoList service
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot list show <event> - Display the <event> RssToDoList feed url
#   hubot list + <event> <link> - Send the <link> to <event> RssToDoList feed
#   hubot list all <event> <limit> - Display all people for that <event> (you can specify an optional <limit>)
#
# Author:
#   athieriot
#   paulgreg

jsdom = require 'jsdom'

module.exports = (robot) ->
  robot.respond /event (\+|\-|all|list|\cancel) ([^ ]*)( .*)?/i, (msg) ->
   server_url = 'http://rsstodolist.appspot.com'

   [action, arg, event] = [msg.match[1], escape(msg.match[2]), msg.match[3]]

   if action == '+' && arg != undefined
      msg.http(server_url + '/add')
         .query(n: event)
         .query(url: arg.trim())
         .get() (err, res, body) ->
            status = res.statusCode 

            if status == 200 || status == 302
               msg.send arg + ' added to' + event
            else
               msg.reply "An error occured on " + event + " feed" 
   else if action == 'all'
      feed_url = encodeURIComponent(server_url + '/?n=' + arg)
      msg.send "Attendance for #{arg}: \n" + 'http://www.seekfreak.com/rss/?url=' + feed_url
   else if action == 'list'
      msg.http(server_url + '/')
         .query(n: arg)
         .query(l: event || 100)
         .get() (err, res, body) ->
            try
              reply = ''
              xml = jsdom.jsdom(body)
              i = 1
              reply = "Attendance for #{arg}: \n"
              for item in xml.getElementsByTagName("rss")[0].getElementsByTagName("channel")[0].getElementsByTagName("item")
                do (item) ->
                  # link = item.getElementsByTagName("link")[0].childNodes[0].nodeValue
                  title = item.getElementsByTagName("title")[0].childNodes[0].nodeValue
                  # descriptionNode = item.getElementsByTagName("description")[0]
                  # description = descriptionNode.childNodes[0].nodeValue if descriptionNode.childNodes.length == 1
                  reply += "#{i}. #{title} \n"
                  i++
                  # reply += " #{description}" if description?
                  # reply += " (#{link})\n"
            catch err
                  msg.reply err
    else if action == '-' && arg != undefined
      msg.http(server_url + '/del')
        .query(n: event)
        .query(url: arg.trim())
        .get() (err, res, body) ->
          status = res.statusCode 

          if status == 200 || status == 302
             msg.send arg + ' removed from' + event
          else
             msg.reply "An error occured on " + event + " feed" 
          msg.send reply "An error occured on " + event + " feed" 

    else if action == 'cancel' && arg != undefined
      msg.http(server_url + '/')
       .query(n: arg)
       .query(l: event || 100)
       .get() (err, res, body) ->
          try
            reply = ''
            xml = jsdom.jsdom(body)
            for item in xml.getElementsByTagName("rss")[0].getElementsByTagName("channel")[0].getElementsByTagName("item")
              do (item) ->
                link = item.getElementsByTagName("link")[0].childNodes[0].nodeValue
                msg.http(server_url + '/del')
                  .query(n: event)
                  .query(url: link.trim())
                  .get() (err, res, body) ->
                    status = res.statusCode 

                    if status == 200 || status == 302
                       msg.send arg + ' removed from' + event
                    else
                       msg.reply "An error occured on " + event + " feed" 
                      msg.send reply "An error occured on " + event + " feed" 
          catch err
                msg.reply err