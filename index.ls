require! {
  './config.json.ls'
  kuromojin: {get-tokenizer}
  '@slack/client': {
    Rtm-client
    Web-client
    RTM_EVENTS: {
      MESSAGE
      REACTION_ADDED
      REACTION_REMOVED
    }
  }
}

rtm-client = new Rtm-client config.slack-token
rtm-client.start!

web-client = new Web-client config.slack-token

rtm-client.on MESSAGE, (message) ->
  if message.text?
    web-client.reactions.add config.ikku-emoji, {
      message.channel
      timestamp: message.ts
    }
