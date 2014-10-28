require 'net/http'
require 'yajl/json_gem'

require_relative 'yeller/backtrace_filter'
require_relative 'yeller/client'
require_relative 'yeller/ignoring_client'
require_relative 'yeller/configuration'
require_relative 'yeller/exception_formatter'
require_relative 'yeller/server'
require_relative 'yeller/version'
require_relative 'yeller/startup_params'
require_relative 'yeller/log_error_handler'

puts "RAILS"
if defined?(::Rails) && defined?(::Rake)
  require 'yeller/rails'
  require 'yeller/rails/tasks'
end

module Yeller
  def self.client(&block)
    config = Yeller::Configuration.new
    block.call(config)
    build_client(config)
  end

  def self.build_client(config)
    if config.ignore_exceptions?
      Yeller::IgnoringClient.new
    else
      Yeller::Client.new(
        config.servers,
        config.token,
        Yeller::StartupParams.defaults(config.startup_params),
        Yeller::BacktraceFilter.new(config.backtrace_filename_filters, config.backtrace_method_filters),
        config.error_handler
      )
    end
  end
end
