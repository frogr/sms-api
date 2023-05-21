# frozen_string_literal: true

class MessageSenderService
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'json'

  PROVIDERS = ['https://mock-text-provider.parentsquare.com/provider1', 'https://mock-text-provider.parentsquare.com/provider2'].freeze

  MAX_RETRIES = 5
  INITIAL_WAIT_TIME = 2

  def initialize(message)
    @message = message
  end

  def call
    weighted_providers = weighted_shuffle(PROVIDERS, [0.7, 0.3])
    retry_with_backoff(MAX_RETRIES, INITIAL_WAIT_TIME) do
      message_sent_with_any_provider?(weighted_providers)
    end
  end

  private

  def message_sent_with_any_provider?(providers)
    success = false
    providers.each do |provider|
      if process_provider(provider)
        success = true
        break
      end
    end

    set_message_status_failed unless success
    success
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

  def retry_with_backoff(max_retries, wait_time, &block)
    retries = 0

    loop do
      return if yield

      retries += 1
      break if retries > max_retries

      schedule_retry(wait_time)
      wait_time *= 2
    end
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
    Rails.logger.info '***' * 10
    Rails.logger.info "Response Code: #{response.code}"
    Rails.logger.info "Response: #{response}"
    Rails.logger.info "Response Body: #{response.body}"
    Rails.logger.info '***' * 10
  end

  def set_message_status_failed
    @message.update(status: 'failed')
    false
  end
end
