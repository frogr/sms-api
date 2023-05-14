class Message < ApplicationRecord
  validates :to_number, :callback_url, :message, presence: true
end
