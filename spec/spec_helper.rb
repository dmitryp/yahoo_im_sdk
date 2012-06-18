require 'bundler/setup'
require 'rspec'
require 'fakeweb'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'yahoo_im_sdk'

def fixture_file(filename)
  return '' if filename == ''
  file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/' + filename)
  File.read(file_path)
end

def stub_get(url, filename, status=nil)
  options = {:body => fixture_file(filename)}
  options.merge!({:status => status}) unless status.nil?

  FakeWeb.register_uri(:get, %r[#{url}], options)
end

def stub_post(url, filename, status=nil)
  options = {:body => fixture_file(filename)}
  options.merge!({:status => status}) unless status.nil?

  FakeWeb.register_uri(:post, %r[#{url}], options)
end

def stub_delete(url, filename, status=nil)
  options = {:body => fixture_file(filename)}
  options.merge!({:status => status}) unless status.nil?

  FakeWeb.register_uri(:delete, %r[#{url}], options)
end

def stub_put(url, filename, status=nil)
  options = {:body => fixture_file(filename)}
  options.merge!({:status => status}) unless status.nil?

  FakeWeb.register_uri(:put, %r[#{url}], options)
end