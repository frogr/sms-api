json.extract! message, :id, :to_number, :callback_url, :message, :status, :created_at, :updated_at
json.url message_url(message, format: :json)
