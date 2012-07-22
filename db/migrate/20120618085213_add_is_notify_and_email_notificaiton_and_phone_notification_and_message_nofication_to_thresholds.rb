class AddIsNotifyAndEmailNotificaitonAndPhoneNotificationAndMessageNoficationToThresholds < ActiveRecord::Migration
  def change
    add_column :thresholds, :is_notify, :boolean

    add_column :thresholds, :phone_notification, :text

    add_column :thresholds, :email_notification, :text

    add_column :thresholds, :message_notification, :string

  end
end
