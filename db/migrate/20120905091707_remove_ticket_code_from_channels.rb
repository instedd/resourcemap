class RemoveTicketCodeFromChannels < ActiveRecord::Migration
  def up
    remove_column :channels, :ticket_code
  end

  def down
    add_column :channels, :ticket_code, :string
  end
end
