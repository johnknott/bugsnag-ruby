require "set"
require "logger"
require "bugsnag/middleware_stack"

module Bugsnag
  class Configuration
    attr_accessor :api_key
    attr_accessor :release_stage
    attr_accessor :notify_release_stages
    attr_accessor :auto_notify
    attr_accessor :use_ssl
    attr_accessor :project_root
    attr_accessor :app_version
    attr_accessor :params_filters
    attr_accessor :ignore_classes
    attr_accessor :endpoint
    attr_accessor :logger
    attr_accessor :middleware
    attr_accessor :delay_with_resque
    attr_accessor :debug

    THREAD_LOCAL_NAME = "bugsnag_req_data"

    DEFAULT_ENDPOINT = "notify.bugsnag.com"

    DEFAULT_PARAMS_FILTERS = ["password"].freeze

    DEFAULT_IGNORE_CLASSES = {
      "ActiveRecord::RecordNotFound" => nil,
      "ActionController::RoutingError" => nil,
      "ActionController::InvalidAuthenticityToken" => nil,
      "CGI::Session::CookieStore::TamperedWithCookie" => nil,
      "ActionController::UnknownAction" => nil,
      "AbstractController::ActionNotFound" => nil,
      "Mongoid::Errors::DocumentNotFound" => nil
    }.freeze

    def initialize
      # Set up the defaults
      self.release_stage = nil
      self.notify_release_stages = ["production"]
      self.auto_notify = true
      self.use_ssl = false
      self.params_filters = Set.new(DEFAULT_PARAMS_FILTERS)
      self.ignore_classes = DEFAULT_IGNORE_CLASSES.dup
      self.endpoint = DEFAULT_ENDPOINT

      # Set up logging
      self.logger = Logger.new(STDOUT)
      self.logger.level = Logger::WARN

      # Configure the bugsnag middleware stack
      self.middleware = Bugsnag::MiddlewareStack.new
      self.middleware.use Bugsnag::Middleware::Callbacks
    end

    def should_notify?
      @release_stage.nil? || @notify_release_stages.include?(@release_stage)
    end

    def request_data
      Thread.current[THREAD_LOCAL_NAME] ||= {}
    end

    def set_request_data(key, value)
      self.request_data[key] = value
    end
    
    def unset_request_data(key, value)
      self.request_data.delete(key)
    end

    def clear_request_data
      Thread.current[THREAD_LOCAL_NAME] = nil
    end
  end
end