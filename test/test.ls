require! {
  nock
  mockery
  chai: {expect}
  './rtm-start-response.json.ls'
}

It = global.it

fake-token = 'xxxx-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxxx-xxxxxxxxxx'

describe 'slack-ikku' ->
  before ->
    # Enable mock of config file
    mockery.register-mock './config.json.ls', do
      slack-token: fake-token
      ikku-emoji: 'test_ikku'
      channels: <[]>
      max-jiamari: 1
      max-jitarazu: 0
    mockery.enable {-warn-on-unregistered}

    # Enable mock of Slack API
    scope = nock 'https://slack.com'
      .post '/api/rtm.start'
      .reply 200 rtm-start-response

  after ->
    mockery.disable!

  before-each ->
    # Purge cache of the app
    delete require.cache['../index.ls']

  @timeout 10000

  It 'works' (done) ->
    require '../index.ls'
    set-timeout done, 5000
