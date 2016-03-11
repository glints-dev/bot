module.exports = (robot) ->
    cronJob = require('cron').CronJob

    shuffle = (a) ->
        i = a.length
        while --i > 0
            j = ~~(Math.random() * (i + 1))
            t = a[j]
            a[j] = a[i]
            a[i] = t
        console.log a
        a

    count = 0
    personnel = ['yingcong', 'yjwong', 'jieqi', 'yanrong', 'oswaldyeo', 'esther', 'gladys', 'alicia','qinen','clarechai','kimberly_lai','kat.cho']

    dutyReminder = ->
        room = 'C0EF6K9UL'
        index = count%personnel.length
        if index == 0
            personnel = shuffle personnel
        roster = [personnel[index], personnel[index+1]]
        announcement = '*Big Brother :cheeps: Announcement Incoming, Everyone Stand in Attention!* :two_men_holding_hands: :two_women_holding_hands:'
        general = '@' + roster.splice(Math.floor(Math.random()*2), 1)[0] + ', that\'s right, *YOU* :middle_finger::skin-tone-3: are in charge of *general cleanliness* :toilet: today. *Arrange tables and chairs* :wheelchair: at the end of the day, *clear all trash* :-os:, and *wash all kitchen utensils* :knife_fork_plate:.'
        trash = '@' + roster[0] + ', sucks to be you :sweat_drops:, but you are on *trash duty* :bomb: today. No running :running:, I\'m looking at you! Tie up all trash bags :moneybag: and *dump them at the refuse* :articulated_lorry: downstairs, plus *put in new plastic bags* :handbag: on the trash cans.'
        badminton = 'Finally, @alicia, please activate your activeSG credits. :badminton_racquet_and_shuttlecock:'
        robot.messageRoom room, announcement
        robot.messageRoom room, general
        robot.messageRoom room, trash
        robot.messageRoom room, badminton
        robot.messageRoom room, ':pray::skin-tone-3::pray::skin-tone-3::pray::skin-tone-3::sensei::pray::skin-tone-3::pray::skin-tone-3::pray::skin-tone-3:'
        count +=2

    tz = 'Asia/Singapore'
    new cronJob('0 0 10 * * 1-5', dutyReminder, null, true, tz)