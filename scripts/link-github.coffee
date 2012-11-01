GitHubApi = require("github")

github = new GitHubApi({
    version: "3.0.0"
})

module.exports = (robot) ->

  robot.respond /tunnukseni on @?([\w .\-]+)\?*$/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      user.username = msg.match[1].trim()
      msg.send "Selvä #{nick}, tunnuksesi on #{user.username}"

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
      msg.send "#{nick}: reposi on #{user.username}/#{user.repository}"

  robot.respond /kommentoi/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      github.pullRequests.getAll {
        user: user.username,
        repo: user.repository,
        state: 'open'
      }, (err, res) ->
        console.log(res)
        if res.length > 0
          pullrequest = res[0]
          msg.send "#{nick}: #{pullrequest.html_url}"
