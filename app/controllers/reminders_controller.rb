class RemindersController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
      end
      format.json { render json: reminders.all.as_json(include: [:repeat,:sites])}
    end
  end

  def create
    reminder = reminders.new params[:reminder]
    reminder.save!
    render json: reminder
  end

end
