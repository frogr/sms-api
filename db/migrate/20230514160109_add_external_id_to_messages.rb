class AddExternalIdToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :external_id, :string
  end
end
