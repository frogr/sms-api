# frozen_string_literal: true

class Message < ApplicationRecord
  validates :to_number, :callback_url, :message, presence: true
end
