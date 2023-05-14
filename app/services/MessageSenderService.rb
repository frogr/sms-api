class MessageSenderService
  require 'net/http'
  require 'uri'
  require 'json'

  def initialize(message)
    @message = message
  end

  def call
    uri = URI.parse("https://mock-text-provider.parentsquare.com/provider1")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "to_number" => @message.to_number,
      "message" => @message.message,
      "callback_url" => @message.callback_url
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    begin
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if response.code.to_i >= 400
        raise "Server Error: #{response.code} #{response.message}"
      end

      Rails.logger.info "***" * 20
      Rails.logger.info "Response Code: #{response.code}"
      Rails.logger.info "Response: #{response}"
      Rails.logger.info "Response Body: #{response.body}"
      Rails.logger.info "***" * 20

      if response.code.to_i == 200
        @message.update(external_id: JSON.parse(response.body)["message_id"])
      end

      rescue => e
        Rails.logger.error "An error occurred: [#{response.code}]: #{e.message}"
    end
  end
end
