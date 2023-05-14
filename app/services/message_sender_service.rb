class MessageSenderService
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'json'

  PROVIDERS = ["https://mock-text-provider.parentsquare.com/provider1", "https://mock-text-provider.parentsquare.com/provider2"]

  def initialize(message)
    @message = message
  end

  def call
    PROVIDERS.each do |provider|
      @message.update(provider: provider)
      response = send_message_to_provider(provider)

      if response.is_a?(Net::HTTPSuccess)
        @message.update(external_id: JSON.parse(response.body)["message_id"])
        break
      end
    end
  end

  def send_message_to_provider(url)
    uri = URI.parse(url)
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

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    Rails.logger.info "***" * 20
    Rails.logger.info "Response Code: #{response.code}"
    Rails.logger.info "Response: #{response}"
    Rails.logger.info "Response Body: #{response.body}"
    Rails.logger.info "***" * 20

    response
  end
end