module.exports = (robot) ->
    cronJob = require('cron').CronJob
    moment = require('moment')

    shuffle = (a) ->
        i = a.length
        while --i > 0
            j = ~~(Math.random() * (i + 1))
            t = a[j]
            a[j] = a[i]
            a[i] = t
        console.log a
        a

    personnel = {
        'product' : {
            'team' : ['yingcong', 'yjwong', 'jieqi', 'yanrong'],
            'days' : [2, 4],
            'name' : 'Product Team'
        },
        'sales': {
            'team' : ['oswaldyeo', 'esther', 'gladys', 'alicia'],
            'days' : [5],
            'name' : 'Sales Team'
        },
        'client': {
            'team' : ['qinen','clarechai','kimberly_lai','kat.cho'],
            'days' : [1 ,3],
            'name' : 'Client Success Team'
        }
    }

    dutyReminder = ->
        # Office
        room = 'C0EF6K9UL'
        # Bombsite
        # room = 'C0RUT2HDF'
        for t, details of personnel
            if moment().weekday() in details['days']
                team = t
                break
        roster = shuffle personnel[team]['team']
        name = personnel[team]['name']
        announcement = "*Big Brother :cheeps: Announcement Incoming, #{name} Stand in Attention!* :two_men_holding_hands: :two_women_holding_hands:"
        general = '@' + roster.splice(Math.floor(Math.random()*roster.length), 1)[0] + ': That\'s right, *YOU* :middle_finger::skin-tone-3: are in charge of *general cleanliness* :toilet: today. *Arrange tables and chairs* :wheelchair: at the end of the day, *clear all trash* :-os:, and *wash all kitchen utensils* :knife_fork_plate:.'
        trash = '@' + roster.splice(Math.floor(Math.random()*roster.length), 1)[0] + ': Sucks to be you :sweat_drops:, but you are on *trash duty* :bomb: today. No running :running:, I\'m looking at you! *Tie up all trash bags* :moneybag: and *dump them at the refuse* :articulated_lorry: downstairs, plus *put in new plastic bags* :handbag: on the trash cans.'
        eyepower = '@' + roster.splice(Math.floor(Math.random()*roster.length), 1)[0] + ': We didn\'t forget you, you really think eyepower :eye: moves the trashbags? Sorry to burst your bubble, but you are no yoda :yoda:, so please *move your butt* :scream_cat: and help out too.'
        supervisor = '@' + roster.splice(Math.floor(Math.random()*roster.length), 1)[0] + ': Your prayers to Lady Luck :no_good::skin-tone-3: is working, you *supervise* :the_horns::skin-tone-3:. But if the job ain\'t got done, the baton\'s :cry: on you! Maybe you should consider praying to another goddess. :yanrong:'
        instructions = 'Please put a :thumbsup::skin-tone-3: below your name once you are done. Otherwise, *WE ALL JUDGE YOU*. Judgement Day awaits. As well as a $10 fine. :looi: will be inspecting. He needs cash.'
        robot.messageRoom room, announcement
        robot.messageRoom room, ':dog::cat::mouse::hamster::rabbit::bear::panda_face:'
        robot.messageRoom room, general
        robot.messageRoom room, trash
        robot.messageRoom room, eyepower
        robot.messageRoom room, supervisor
        robot.messageRoom room, ':leopard::tiger2::water_buffalo::ox::cow2::dromedary_camel::camel:'
        robot.messageRoom room, instructions
        robot.messageRoom room, ':pray::skin-tone-3::pray::skin-tone-3::pray::skin-tone-3::sensei::pray::skin-tone-3::pray::skin-tone-3::pray::skin-tone-3:'

    tz = 'Asia/Singapore'
    new cronJob('0 0 10 * * 1-5', dutyReminder, null, true, tz)