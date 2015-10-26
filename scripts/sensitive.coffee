# Description:
#   Hubot has feelings too, you know
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#
# Author:
#   iangreenleaf

messages = [
  "Hey, that stings."
  "Is that tone really necessary?"
  "Robots have feelings too, you know."
  "You should try to be nicer."
  "*sizzle* Ouch, hear those burn marks on my metal heart?"
  "Sticks and stones cannot pierce my anodized exterior, but words *do* hurt me."
  "I'm sorry, I'll try to do better next time."
  "https://s-media-cache-ak0.pinimg.com/736x/e6/78/f3/e678f395bfe15e0e3363112674e490a4.jpg"
]

hurt_feelings = (msg) ->
  msg.send msg.random messages

module.exports = (robot) ->
  pejoratives = "stupid|buggy|useless|dumb|suck|crap|shitty|idiot|fat|greedy|evil|horrible|freak|damn|lazy|angry"

  r = new RegExp "(#{pejoratives})", "i"
  robot.hear r, hurt_feelings
