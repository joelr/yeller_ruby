require File.expand_path('../server', __FILE__)

module Yeller
  class Configuration
    attr_reader :token, :servers, :startup_params, :error_handler, :project_root, :development_environments
    DEFAULT_SERVERS = [
      Yeller::SecureServer.new("collector1.yellerapp.com", 443),
      Yeller::SecureServer.new("collector2.yellerapp.com", 443),
      Yeller::SecureServer.new("collector3.yellerapp.com", 443),
      Yeller::SecureServer.new("collector4.yellerapp.com", 443),
      Yeller::SecureServer.new("collector5.yellerapp.com", 443),
    ]

    def initialize
      @servers = DEFAULT_SERVERS
      @startup_params = {}
      @error_handler = Yeller::LogErrorHandler.new
      @development_environments = Set.new(['development', 'test'])
    end

    def remove_default_servers
      @servers = []
      self
    end

    def add_server(host, port=443)
      @servers << Yeller::SecureServer.new(host, port)
      self
    end

    def add_insecure_server(host, port=80)
      @servers << Yeller::Server.new(host, port)
    end

    def backtrace_filename_filters
      filters = []
      if defined?(Gem)
        Gem.path.each do |gem_path|
          if 0 < gem_path.size
            filters << [gem_path, 'GEM_ROOT']
          end
        end
      end
      if 0 < project_root.size
        filters << [project_root, 'PROJECT_ROOT']
      end
      filters
    end

    def backtrace_method_filters
      filters = []
      if defined?(Rails)
        filters << [/_run__\d+__.*callbacks/, 'process_callbacks']
      end
      filters
    end

    def environment=(new_environment)
      @startup_params[:"application-environment"] = new_environment
    end

    def host=(new_host)
      @startup_params[:host] = new_host
    end

    def project_root=(new_project_root)
      @project_root = new_project_root
    end

    def project_root
      return @project_root if @project_root
      if defined?(::Rails)
        if ::Rails.respond_to?(:root)
          ::Rails.root.to_s
        elsif defined?(::RAILS_ROOT)
          ::RAILS_ROOT
        end
      else
        Dir.pwd
      end
    end

    def development_environments=(new_development_environments)
      @development_environments = new_development_environments
    end

    def ignore_exceptions?
      development_environments.include?(
        @startup_params[:"application-environment"])
    end

    def token=(token)
      @token = token
    end

    def error_handler=(new_error_handler)
      @error_handler = new_error_handler
    end

    def project_root=(new_project_root)
      @project_root = new_project_root
    end

    def skip_exceptions
      Yeller::SkipExceptions.new(
        @skip_exceptions || [],
        @skip_exceptions_callback || Proc.new {|e| false}
      )
    end

    def skip_exceptions=(skip_exceptions)
      @skip_exceptions = skip_exceptions
    end

    def skip_exceptions_callback(skip_exceptions_callback)
      @skip_exceptions_callback = skip_exceptions_callback
    end
  end
end
