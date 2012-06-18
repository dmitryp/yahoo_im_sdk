lib = File.expand_path('../', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bundler/setup'
require 'httparty'
require 'crack'
require "yahoo_im_sdk/version"
require 'yahoo_im_sdk/extras/httparty_ext'

module YahooImSdk


   class Client
      class Error < StandardError; end
      class SessionExpired < Error; end
      class UserExistsError < Error; end
      class UserDoesNotExistError < Error; end
      class UnableToProcessRequestError < Error; end

      Realm = 'yahooapis.com'

      URL_OAUTH_DIRECT = 'https://login.yahoo.com/WSLogin/V1/get_auth_token'
      URL_OAUTH_ACCESS_TOKEN = 'https://api.login.yahoo.com/oauth/v2/get_token'
      URL_YM_SESSION = 'http://developer.messenger.yahooapis.com/v1/session'
      URL_YM_PRESENCE = 'http://developer.messenger.yahooapis.com/v1/presence'
      URL_YM_CONTACT = 'http://developer.messenger.yahooapis.com/v1/contacts'
      URL_YM_MESSAGE = 'http://developer.messenger.yahooapis.com/v1/message/yahoo/USER'
      URL_YM_NOTIFICATION = 'http://developer.messenger.yahooapis.com/v1/notifications'
      URL_YM_NOTIFICATION_LONG = 'http://NOTIFICATION_SERVER/v1/pushchannel/USER'
      URL_YM_BUDDYREQUEST = 'http://developer.messenger.yahooapis.com/v1/buddyrequest/yahoo/USER'
      URL_YM_GROUP = 'http://developer.messenger.yahooapis.com/v1/group/GROUP/contact/yahoo/USER'

      def initialize(username, password, consumer_key, consumer_secret, options = {})
        @username         = username
        @password         = password
        @consumer_key     = consumer_key
        @consumer_secret  = consumer_secret
        @debug = options[:debug]
      end

      def debug?
        !!@debug
      end

      def oauth_nonce
        rand(50000000)
      end

      def oauth_timestamp
        Time.now.to_i
      end
      #
      def oauth_signature
        "#{@consumer_secret}&"
      end
      #
      # Pre-Authorized Request Token
      def get_request_token
        params = {
          :oauth_consumer_key => @consumer_key ,
          :login => @username,
          :passwd => @password
        }
        response = HTTPartyExt.get(URL_OAUTH_DIRECT, :query => params)

        raise Error, "Failed fetching request token: #{response.code}. #{response.message}" unless response.code == 200
        response.body.split(/=/).last.strip
      end


      def request_token
        @request_token ||= get_request_token
      end

      def get_access_token
        params = {
          :oauth_consumer_key => @consumer_key,
          :oauth_nonce => oauth_nonce,
          :oauth_signature => oauth_signature,
          :oauth_signature_method => 'PLAINTEXT',
          :oauth_timestamp => oauth_timestamp,
          :oauth_token => request_token,
          :oauth_version => '1.0'
        }
        response = HTTPartyExt.get(URL_OAUTH_ACCESS_TOKEN, :query => params, :header => {'Content-Type' => 'application/x-www-form-urlencoded'})

        raise Error, "Failed fetching access token: #{response.code}. #{response.message}" unless response.code == 200
        response.body.strip.split(/&/).inject({}){|res, pair|  key, val = pair.split(/=/); res.update(key.to_sym => val)}
      end

      def access_token
        if @access_token.nil? || oauth_expired?
          debug('Trying to fetch access token')
          @request_token = get_request_token
          @access_token  = get_access_token
          @oauth_expired_at = Time.now + (@access_token[:oauth_expires_in].to_i - 300)
          if session_id
            update_session
          end
        end
        @access_token ||= get_access_token
      end

      def oauth_expired?
        oauth_expired_at && oauth_expired_at < Time.now
      end

      def oauth_expired_at
        @oauth_expired_at
      end

      def consumer
        @consumer
      end

      def auth_header
        params = {
          :oauth_consumer_key => @consumer_key,
          :oauth_nonce => oauth_nonce,
          :oauth_signature => oauth_signature + access_token[:oauth_token_secret],
          :oauth_signature_method => 'PLAINTEXT',
          :oauth_timestamp => oauth_timestamp,
          :oauth_token => access_token[:oauth_token],
          :oauth_version => '1.0',
          :notifyServerToken => '1'
        }

        "OAuth realm=\"#{Realm}\", " + params.map { |k,v| "#{k}=\"#{(v)}\"" }.join(", ")
      end


      def signin
        data = '{"presenceState" :  0, "presenceMessage" : ""}'
        response = HTTPartyExt.post(URL_YM_SESSION, :body => data, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})
        check_response(response, "Signing-in")
        @session_id = response.parsed_response["sessionId"]
      end

      def logout
        response = HTTPartyExt.delete(URL_YM_SESSION, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        @access_token = nil
        @session_id = nil
        @request_token = nil

        check_response(response, "Logout")
      end

      def check_session
        response = HTTPartyExt.get(URL_YM_SESSION, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        check_response(response, "Checking session")
        rescue SessionExpired
          false
      end

      def update_session
        response = HTTPartyExt.put(URL_YM_SESSION + '/keepalive', :query => {:sid => @session_id, :notifyServerToken => 1 }, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        check_response(response, "Updating session")
        true
      end

      def session_id
        @session_id
      end

      def session_id=(sid)
        @session_id = sid
      end

      def precence(state = 0, message = nil)
        message = "{\"presenceState\" :  \"#{state}\", \"presenceMessage\" :  \"#{message}\"}"
        response = HTTPartyExt.put(URL_YM_PRESENCE, :body => message, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        check_response(response, "Changig precence")
      end

      def contacts
        response = HTTPartyExt.get(URL_YM_CONTACT, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        check_response(response, "Fetching contacts")
        response.parsed_response['contacts']
      end

      def send_message(user, message = 'test')
        url = URL_YM_MESSAGE.gsub(/USER/, normalize_yahoo_id(user))

        message = "{\"message\" :  \"#{message}\"}"
        response = HTTPartyExt.post(url, :body => message, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        check_response(response, "Sending message")
      end

      # yahoo.add_contact('user@yahoo.com', {:group => 'Friends', :message => 'Hello'})
      def add_contact(user, options = {})
        group = options.delete(:group) || 'Friends'
        message = options.delete(:message)
        url = URL_YM_GROUP.gsub(/GROUP/, group).gsub(/USER/, normalize_yahoo_id(user))
        message = "{\"message\" :  \"#{message}\"}"

        response = HTTPartyExt.put(url, :body => message, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})
        check_response(response, "Adding contact")
      end

      def rm_contact(user, group = 'Friends')
        url = URL_YM_GROUP.gsub(/GROUP/, group).gsub(/USER/, normalize_yahoo_id(user))
        response = HTTPartyExt.delete(url, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        check_response(response, "Deleting contact")
      end

      def response_contact(user, accept = true, message = nil)
        url = URL_YM_BUDDYREQUEST.gsub(/USER/, normalize_yahoo_id(user))
        if accept
          message = "{\"authReason\" :  \"Welcome\"}"
          response = HTTPartyExt.post(url, :body => message, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})
        else
          message = "{\"authReason\" :  \"Goodbye. We hope to see you soon\"}"
          response = HTTPartyExt.delete(url, :body => message, :query => {:sid => @session_id}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})
        end

        check_response(response, "Accepting contact")
      end

      def get_notifications(seq = 0, count = 10)
        response = HTTPartyExt.get(URL_YM_NOTIFICATION, :query => {:sid => @session_id, :seq => seq, :count => count}, :headers => {'Content-Type' => 'application/json', 'charset' => 'utf-8', 'Authorization' => auth_header})

        check_response(response, "Getting notifications")
        response.parsed_response
      end

      def normalize_yahoo_id(id)
        id.strip.gsub(/@yahoo\.com$/,'')
      end

      def debug(message)
        puts message if debug?
      end

      def check_response(response, error_message)
        debug response

        if response.code == 200 || response.code == 201
          true
        elsif response.code == 999
          raise UnableToProcessRequestError, "#{error_message} failed. Error 999"
        elsif response.parsed_response['code']
          case response.parsed_response['code']
          when 2  : raise UserExistsError, "#{error_message} failed. #{response.parsed_response['detail']}"
          when 3  : raise UserDoesNotExistError, "#{error_message} failed. #{response.parsed_response['detail']}"
          when 28 : raise SessionExpired, "#{error_message} failed. #{response.parsed_response['detail']}"
          else
            raise Error, "#{error_message} failed: #{response.parsed_response['code']}. #{response.parsed_response['details']}"
          end
        else
          raise Error, "#{error_message} failed: #{response.code}. #{response.message}"
        end
      end

      RESERVED_CHARACTERS = /[^a-zA-Z0-9\-\.\_\~]/

      def escape(value)
        URI::escape(value.to_s, RESERVED_CHARACTERS)
      rescue ArgumentError
        URI::escape(value.to_s.force_encoding(Encoding::UTF_8), RESERVED_CHARACTERS)
      end
    end


end
