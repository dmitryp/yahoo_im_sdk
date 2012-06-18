require 'spec_helper'

describe "client" do
  def yahoo
    @yahoo ||= YahooImSdk::Client.new('username', 'password', 'consumer_key', 'consumer_secret')
  end

  it "should return request token" do
    stub_get(YahooImSdk::Client::URL_OAUTH_DIRECT, 'request_token.txt')
    yahoo.get_request_token.should eql("abcdefgk")
  end

  it "should return invalid login" do
    stub_get(YahooImSdk::Client::URL_OAUTH_DIRECT, 'login_does_not_exits.txt', 403)
    lambda{ yahoo.get_request_token}.should raise_error(YahooImSdk::Client::Error)
  end

  it "should return invalid password" do
    stub_get(YahooImSdk::Client::URL_OAUTH_DIRECT, 'invalid_password.txt', 403)
    lambda{ yahoo.get_request_token}.should raise_error(YahooImSdk::Client::Error)
  end

  it "should get access token" do
    stub_get(YahooImSdk::Client::URL_OAUTH_DIRECT, 'request_token.txt')
    stub_get(YahooImSdk::Client::URL_OAUTH_ACCESS_TOKEN, 'access_token.txt')

    yahoo.get_access_token

    yahoo.access_token[:oauth_authorization_expires_in].should eql("807478353")
    yahoo.access_token[:oauth_expires_in].should eql("3600")
    yahoo.access_token[:oauth_session_handle].should eql("oauth_session_handel")
    yahoo.access_token[:oauth_token].should eql("oauth_token")
    yahoo.access_token[:oauth_token_secret].should eql("secret")
    yahoo.access_token[:xoauth_yahoo_guid].should eql("xoauth_yahoo_guid")
  end

  it "should signin" do
    stub_get(YahooImSdk::Client::URL_OAUTH_DIRECT, 'request_token.txt')
    stub_get(YahooImSdk::Client::URL_OAUTH_ACCESS_TOKEN, 'access_token.txt')
    stub_post(YahooImSdk::Client::URL_YM_SESSION, 'signin.txt')
    yahoo.signin

    yahoo.session_id.should eql('session_id')
  end

  it "should logout" do
    stub_get(YahooImSdk::Client::URL_OAUTH_DIRECT, 'request_token.txt')
    stub_get(YahooImSdk::Client::URL_OAUTH_ACCESS_TOKEN, 'access_token.txt')
    stub_post(YahooImSdk::Client::URL_YM_SESSION, 'signin.txt')
    yahoo.signin

    stub_delete(YahooImSdk::Client::URL_YM_SESSION, "logout.txt")
    # FakeWeb.register_uri(:delete, YahooImSdk::Client::URL_YM_SESSION, :status => ["200", "OK"])
    yahoo.logout.should eql(true)
  end

end