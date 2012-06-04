class RemindersController < ApplicationController
  before_filter :authenticate_user!

  def create
    reminder = reminders.new params[:reminder]
    reminder.save!
    render json: reminder
  end

end
