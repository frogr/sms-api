# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :to_number
      t.string :callback_url
      t.string :message
      t.string :status

      t.timestamps
    end
  end
end
