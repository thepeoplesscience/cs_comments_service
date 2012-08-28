require 'rubygems'
require 'bundler'

Bundler.setup
Bundler.require

require 'tire/queries/more_like_this'

env_index = ARGV.index("-e")
env_arg = ARGV[env_index + 1] if env_index
env = env_arg || ENV["SINATRA_ENV"] || "development"

RACK_ENV = env

Sinatra::Base.environment = env

module CommentService
  class << self; attr_accessor :config; end
  API_VERSION = 'v1'
  API_PREFIX = "/api/#{API_VERSION}"
end

set :cache, Dalli::Client.new

dirname = File.dirname(__FILE__)
CommentService.config = YAML.load_file(dirname + "/application.yml").with_indifferent_access

Tire.configure do
  url CommentService.config[:elasticsearch_server]
end

Mongoid.load!(dirname + "/mongoid.yml")
Mongoid.logger.level = Logger::INFO

Dir[dirname + '/../lib/**/*.rb'].each {|file| require file}
Dir[dirname + '/../models/*.rb'].each {|file| require file}
Dir[dirname + '/../models/*/*.rb'].each {|file| require file}

Mongoid.observers = PostReplyObserver, PostTopicObserver, AtUserObserver
Mongoid.instantiate_observers

config = (CommentService.config[:callback] || {})[:notifications] || {}
NotificationCallback.api_key = CommentService.config[:api_key]
NotificationCallback.load_config(config)

APIPREFIX = CommentService::API_PREFIX
DEFAULT_PAGE = 1
DEFAULT_PER_PAGE = 20
