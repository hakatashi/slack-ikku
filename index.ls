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
text = message.file?.initial_comment?.comment or message.text
return unless text?

return unless config.channels.length is 0 or message.channel in config.channels

text .= replace /^<.+?>:?/ ''

tokens = tokenizer.tokenize nfkc text

target-regions = [5 7 5]
regions = [0]

for token in tokens
  continue if token.pos is \記号
  continue if token.surface_form in <[、 ! ?]>

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

add-reaction = (emoji) ->
  | message.file? =>
    web-client.reactions.add emoji, {
      file: message.file.id
      file_comment: message.file.initial_comment.id
    }
  | otherwise =>
    web-client.reactions.add emoji, {
      message.channel
      timestamp: message.ts
    }

add-reaction config.ikku-emoji

if jiamari > 0 and config.jiamari-emoji?length > 0
  add-reaction config.jiamari-emoji

if jitarazu > 0 and config.jitarazu-emoji?length > 0
  add-reaction config.jitarazu-emoji

console.log "[#{Date!}] Found ikku: #{util.inspect message}"
