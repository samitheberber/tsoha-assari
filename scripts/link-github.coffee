class TsohaHub
  constructor: (@robot) ->
    @github = require('githubot')(@robot)
    @org = "tsoha-syksy2012"

  formatRepo: (username) ->
    "#{@org}/#{username}"

  formatRepoUrl: (username) ->
    "/repos/#{@formatRepo username}"

  createRepository: (username, cb) ->
    @github.post "/orgs/#{@org}/repos", {
      name: username,
      has_wiki: false,
      auto_init: true,
      team_id: @getTeamId()
    }, cb

  getRepository: (username, cb) ->
    @github.get @formatRepoUrl(username), cb

  setTeam: (team_id, cb) ->
    @robot.brain.data.current_team = team_id
    @getTeam cb

  getTeamId: () ->
    @robot.brain.data.current_team

  getTeam: (cb) ->
    @github.get "/teams/#{@getTeamId()}", cb

  getCurrentPullRequest: (username, cb) ->
    @github.get "#{@formatRepoUrl(username)}/pulls", {state: "open"}, (pullrequests) ->
      cb pullrequests[0]

  createNewBranch: (username, name, cb) ->
    @github.branches(@formatRepo username).create name, cb

  createNewPullRequest: (username, name, branch, cb) ->
    @github.post "#{@formatRepoUrl username}/pulls", {
      title: name,
      base: "master",
      head: branch
    }, cb

  createEmptyCommit: (username, branch, cb) ->
    repo_url = @formatRepoUrl username
    commit_sha = branch.commit.sha
    _this = this
    @github.get branch.commit.url, (commit) ->
      _this.github.post "#{repo_url}/git/trees", {
        base_tree: commit.tree.sha,
        tree: []
      }, (tree) ->
        _this.github.post "#{repo_url}/git/commits", {
          parents: [commit_sha],
          tree: tree.sha,
          message: "Uusi viikko luotu"
        }, (new_commit) ->
          _this.github.post "#{repo_url}/git/refs/heads/#{branch.name}", {
            sha: new_commit.sha
          }, (data) ->
            cb(branch)

  createWeek: (username, week, cb) ->
    _this = this
    @createNewBranch username, "week-#{week}", (branch) ->
      _this.createEmptyCommit username, branch, (branch) ->
        _this.createNewPullRequest(username, "Viikko #{week}", branch.name, cb)

module.exports = (robot) ->

  tsohahub = new TsohaHub robot

  robot.respond /aktiivinen tiimi on (.+)$/i, (msg) ->
    tsohahub.setTeam msg.match[1].trim(), (team) ->
      msg.send "Aktiiviseksi tiimiksi asetettu #{team.name}"

  robot.respond /tunnukseni on @?([\w .\-]+)\?*$/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      user.username = msg.match[1].trim()
      msg.send "Selvä #{nick}, sinulle luodaan repository..."
      tsohahub.createRepository user.username, (repository) ->
        msg.send "#{nick}: #{repository.html_url}"

  robot.respond /Mikä(.+)repo(.*)\?/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      tsohahub.getRepository user.username, (repository) ->
        msg.send "#{nick}: #{repository.html_url}"

  robot.respond /luo viikolle (.+) haara/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      tsohahub.createWeek user.username, msg.match[1].trim(), (pullRequest) ->
        msg.send "#{nick}: Viikon edistymistä voit seurata: #{pullRequest.html_url}"


  robot.respond /kommentoi/i, (msg) ->
    nick = msg.message.user.name
    users = robot.usersForFuzzyName(nick)
    if users.length is 1
      user = users[0]
      tsohahub.getCurrentPullRequest user.username, (pullRequest) ->
        if pullRequest?
          msg.send "tsohaohjaajat: #{pullRequest.html_url}"
        else
          msg.send "#{nick}: Sinulla ei ole avointa pull requestia"
