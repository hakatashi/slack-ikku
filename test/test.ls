require! {
  nock
  mockery
  chai: {expect}
  'mock-socket': {Server, Web-socket}
  './rtm-start-response.json.ls'
}

It = global.it

fake-token = 'xxxx-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxxx-xxxxxxxxxx'

describe 'slack-ikku' ->
  scope = null

  before ->
    # Mock of config file
    mockery.register-mock './config.json.ls' do
      slack-token: fake-token
      ikku-emoji: 'test_ikku'
      channels: <[]>
      max-jiamari: 1
      max-jitarazu: 0

    # Polyfill lacking 'on' feature
    Web-socket::on = (name, handler) ->
      switch name
        | \open => @onopen = handler
        | \message => @onmessage = handler
        | \close => @onclose = handler
        | \error => @onerror = handler

    mockery.register-mock 'ws' Web-socket

  before-each ->
    # Enable mock for Slack APIs
    scope := nock 'https://slack.com'
      .post '/api/rtm.start'
      .reply 200 rtm-start-response

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
    scope.on \replied ->
      mocked-socket = new Server 'wss://test.slack-msgs.com/websocket/xxxxx'
      mocked-socket.on \connection -> console.log &
      done!

    # Execute App
    require '../index.ls'
