# YahooImSdk

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'yahoo_im_sdk'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yahoo_im_sdk

## Usage

A Ruby SDK and example for using the Yahoo! Messenger API
(http://developer.yahoo.com/messenger/)


Example:

    @yahoo = YahooImSdk::Client.new('username', 'password', 'consumer_key', 'consumer_secret')
    @yahoo.signin


Send message:

    @yahoo.send_message('user@yahoo.com', 'Hello!')


Get messages/notifications:

    @yahoo.get_notifications


Add contact

    @yahoo.add_contact('user@yahoo.com', {:group => 'Friends', :message => 'Hello'})



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
