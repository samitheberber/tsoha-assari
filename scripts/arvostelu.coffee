module.exports = (robot) ->
  robot.hear /arvostel/i, (msg) ->
    msg.send "#{msg.message.user.name}: Kaikki aikanaan :)"
