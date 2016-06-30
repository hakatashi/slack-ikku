require! {
  mockery
  chai: {expect}
}

It = global.it

describe 'slack-ikku' ->
  before ->
    # Enable
    mockery.register-mock './config.json.ls', {hoge: 1}
    mockery.enable {-warn-on-unregistered}

  after ->
    mockery.disable!

  before-each ->
    # Purge cache of the app
    delete require.cache['../']

  It 'works' ->
    require '../'
