# frozen_string_literal: true

class MessageSenderService
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'json'

  PROVIDERS = ['https://mock-text-provider.parentsquare.com/provider1', 'https://mock-text-provider.parentsquare.com/provider2'].freeze

  def initialize(message)
    @message = message
  end

  def call
    retries = 0
    max_retries = 5
    wait_time = 2
    weighted_providers = weighted_shuffle(PROVIDERS, [0.7, 0.3])

    loop do
      break if message_sent_with_any_provider?(weighted_providers)

      retries += 1
      break if retries > max_retries

      schedule_retry(wait_time)
      wait_time *= 2
    end
  end

  def message_sent_with_any_provider?(providers)
    providers.each do |provider|
      return true if process_provider(provider)
    end
    @message.update(status: 'failed')
    false
  end

  def process_provider(provider)
    @message.update(provider: provider)
    response = send_message_to_provider(provider)

    if response.is_a?(Net::HTTPSuccess)
      handle_success_response(response)
      true
    else
      Rails.logger.error("Failed to send message with provider: #{provider}")
      false
    end
  end

  def handle_success_response(response)
    body = JSON.parse(response.body)
    @message.update(external_id: body['message_id'], status: 'delivered')
  end

  def schedule_retry(wait_time)
    MessageSenderJob.set(wait: wait_time.seconds).perform_later(@message.id)
  end

  def send_message_to_provider(url)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.dump(message_params)

    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    log(response)
    response
  end

  def message_params
    {
      'to_number' => @message.to_number,
      'message' => @message.message,
      'callback_url' => @message.callback_url
    }
  end

  def weighted_shuffle(array, weights)
    raise ArgumentError, 'Array and weights sizes must be equal' unless array.size == weights.size

    temp_array = array.zip(weights).flat_map { |n, freq| Array.new((freq * 10).round, n) }
    temp_array.shuffle
  end

  def log(response)
    Rails.logger.info("Message sent to #{@message.provider} with response: #{response}")
    Rails.logger.info '***' * 20
    Rails.logger.info "Response Code: #{response.code}"
    Rails.logger.info "Response: #{response}"
    Rails.logger.info "Response Body: #{response.body}"
    Rails.logger.info '***' * 20
  end
end
