require! {
  util
  './config.json.ls'
  'prelude-ls': {fold1, zip-with, max, map}
  kuromojin: {get-tokenizer}
  unorm: {nfkc}
  '@slack/client': {
    Rtm-client
    Web-client
    RTM_EVENTS: {MESSAGE}
    CLIENT_EVENTS: {
      RTM: {DISCONNECT}
    }
  }
}

tokenizer <- get-tokenizer!then

rtm-client = new Rtm-client config.slack-token
rtm-client.start!

web-client = new Web-client config.slack-token

rtm-client.on DISCONNECT, -> process.exit 1

message <- rtm-client.on MESSAGE
return unless message.text?

return unless config.channels.length is 0 or message.channel in config.channels

message.text .= replace /^<.+?>:?/ ''

tokens = tokenizer.tokenize nfkc message.text

target-regions = [5 7 5]
regions = [0]

for token in tokens
  continue if token.pos is \記号
  continue if token.basic_form is '、'

  pronunciation = token.pronunciation or token.surface_form
  return unless pronunciation.match /^[ぁ-ゔァ-ヺー…]+$/

  region-length = pronunciation.replace /[ぁぃぅぇぉゃゅょァィゥェォャュョ…]/g, '' .length

  if token.pos in <[助詞 助動詞]> or token.pos_detail_1 in <[接尾 非自立]>
    regions[* - 1] += region-length
  else if regions[* - 1] < target-regions[regions.length - 1] or regions.length is 3
    regions[* - 1] += region-length
  else
    regions.push region-length

return if regions.length isnt target-regions.length

jitarazu = regions |> zip-with (-), target-regions |> map max 0 |> fold1 (+)
jiamari = target-regions |> zip-with (-), regions |> map max 0 |> fold1 (+)

return if jitarazu > config.max-jitarazu or jiamari > config.max-jiamari

web-client.reactions.add config.ikku-emoji, {
  message.channel
  timestamp: message.ts
}

console.log "[#{Date!}] Found ikku: #{util.inspect message}"
