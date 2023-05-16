class MessageSenderJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    service = MessageSenderService.new(message)
    service.call
  end
end
