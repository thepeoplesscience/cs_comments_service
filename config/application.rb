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

APIPREFIX = CommentService::API_PREFIX
DEFAULT_PAGE = 1
DEFAULT_PER_PAGE = 20

require 'action_mailer'

ActionMailer::Base.view_paths = [File.dirname(__FILE__) + '/../templates/mailer']

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = false
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.default :charset => "utf-8"

email_config = YAML.load_file(File.dirname(__FILE__) + '/email.credentials.yml')

ActionMailer::Base.smtp_settings = {
  address: "smtp.gmail.com",
  port: 587,
  domain: "localhost:4567",
  authentication: "plain",
  enable_starttls_auto: true,
  user_name: email_config["username"],
  password: email_config["password"],
}
