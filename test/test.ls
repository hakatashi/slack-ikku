require! {
  nock
  mockery
  chai: {expect}
  'mock-socket': {Server, Web-socket}
  './rtm-start-response.json.ls'
}

It = global.it

fake-token = 'xxxx-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxxx-xxxxxxxxxx'
fake-user = 'DFAKEUSER'
fake-channel = 'DFAKECHAN'
fake-ts = '1111111111.000000'

describe 'slack-ikku' ->
  before ->
    # Mock of config file
    mockery.register-mock './config.json.ls' do
      slack-token: fake-token
      ikku-emoji: 'test_ikku'
      channels: <[]>
      max-jiamari: 1
      max-jitarazu: 0

    # Polyfill lacking 'on' feature
    Web-socket::on = (name, listener) ->
      switch name
        | \open => @onopen = listener
        | \message => @onmessage = (raw) ~> listener.call this, raw.data
        | \close => @onclose = listener
        | \error => @onerror = listener

    mockery.register-mock 'ws' Web-socket

  before-each ->
    # Enable require mocks
    mockery.enable {-warn-on-unregistered}

  after-each ->
    # Purge cache of the app
    delete require.cache['../index.ls']

    # Purge nock
    nock.clean-all!

    mockery.disable!

  @timeout 10000

  It 'works' (done) ->
    # First, execute the app
    require '../index.ls'

    # Mock rtm.start API request
    rtm-start = nock 'https://slack.com'
      .post '/api/rtm.start' token: fake-token
      .reply 200 rtm-start-response
    <- rtm-start.on \replied

    # Execute server and wait for connection
    mock-server = new Server rtm-start-response.url
    server, web-socket <- mock-server.on \connection

    # Send message that matches 575
    mock-server.send JSON.stringify do
      type: \message
      ts: fake-ts
      channel: fake-channel
      user: fake-user
      text: '古池や蛙飛び込む水の音'

    # Mock reactions.add API request
    reactions-add = nock 'https://slack.com'
      .post '/api/reactions.add' do
        token: fake-token
        channel: fake-channel
        timestamp: fake-ts
        name: 'test_ikku'
      .reply 200 {+ok}
    request <- reactions-add.on \replied

    # OK!
    done!
