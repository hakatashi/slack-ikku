require! {
  './config.json.ls'
  'prelude-ls': {fold1, zip-with, max, map}
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

tokenizer <- get-tokenizer!then

rtm-client = new Rtm-client config.slack-token
rtm-client.start!

web-client = new Web-client config.slack-token

message <- rtm-client.on MESSAGE
return unless message.text?

tokens = tokenizer.tokenize message.text

target-regions = [5 7 5]
regions = [0]

for token in tokens
  continue if token.pos is \記号

  pronunciation = token.pronunciation or token.surface_form
  return unless pronunciation.match /^[ァ-ヺー]+$/

  region-length = pronunciation.replace /[ァィゥェォャュョ]/g, '' .length

  if token.pos in <[助詞 助動詞]> or token.pos_detail_1 is \接尾
    regions[* - 1] += region-length
  else if regions[* - 1] < target-regions[regions.length - 1] or regions.length is 3
    regions[* - 1] += region-length
  else
    regions.push region-length

jitarazu = regions |> zip-with (-), target-regions |> map max 0 |> fold1 (+)
jiamari = target-regions |> zip-with (-), regions |> map max 0 |> fold1 (+)

return if jitarazu > config.max-jitarazu or jiamari > config.max-jiamari

web-client.reactions.add config.ikku-emoji, {
  message.channel
  timestamp: message.ts
}
