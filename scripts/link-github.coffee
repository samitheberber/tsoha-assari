module.exports = (robot) ->
  robot.respond /reponi on @?([\w .\-]+)\?*$/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      user.repository = msg.match[1].trim()
      msg.send "Selvä #{nick}, reposi on #{user.repository}"

  robot.respond /Mikä(.+)repo(.*)\?/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      msg.send "#{nick}: reposi on #{user.repository}"
