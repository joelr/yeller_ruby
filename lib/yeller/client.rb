module Yeller
  class Client
    attr_reader :backtrace_filter, :token

    def initialize(servers, token, startup_params, backtrace_filter, error_handler)
      @servers = servers
      @last_server = rand(servers.size)
      @startup_params = startup_params
      @token = token
      @error_handler = error_handler
      @backtrace_filter = backtrace_filter
      @reported_error = false
    end

    def report(exception, options={})
      hash = ExceptionFormatter.format(exception, backtrace_filter, options)
      serialized = JSON.dump(@startup_params.merge(hash))
      report_with_roundtrip(serialized, 0)
    end

    def report_with_roundtrip(serialized, error_count)
      next_server.client.post("/#{@token}", serialized, {"Content-Type" => "application/json"})
      @reported_error ||= true
    rescue StandardError => e
      if error_count <= (@servers.size * 2)
        report_with_roundtrip(serialized, error_count + 1)
      else
        @error_handler.handle(e)
      end
    end

    def record_deploy(revision, user, environment)
      post = Net::HTTP::Post.new("/#{@token}/deploys")
      post.set_form_data('revision' => revision,
                         'user' => user,
                         'environment' => environment)
      next_server.client.request(post)
    end

    def enabled?
      true
    end

    def reported_error?
      @reported_error
    end

    def inspect
      "#<Yeller::Client enabled=true token=#{@token.inspect}>"
    end

    private

    def next_server
      index = @last_server
      @last_server = (index + 1) % @servers.size
      @servers[index]
    end
  end
end
