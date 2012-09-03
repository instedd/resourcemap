class AddTicketCodeToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :ticket_code, :string
  end
end
