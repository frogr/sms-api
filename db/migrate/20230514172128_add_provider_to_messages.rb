# frozen_string_literal: true

class AddProviderToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :provider, :string
  end
end
