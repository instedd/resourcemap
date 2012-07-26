class RemindersController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Reminders", collection_reminders_path(collection)
      end
      format.json { render json: reminders.all.as_json(include: [:repeat], methods: [:reminder_date], except: [:schedule])}
    end
  end

  def create
    reminder = reminders.new params[:reminder].except(:sites)
    reminder.sites = Site.get_site_id_and_name params[:reminder][:sites] if params[:reminder][:sites]
    reminder.save!
    render json: reminder
  end
  
  def update
    reminder = reminders.find params[:id]
    reminder.update_attributes! params[:reminder].except(:sites)
    reminder.sites = Site.get_site_id_and_name params[:reminder][:sites] if params[:reminder][:sites]
    reminder.save! 
    render json: reminder
  end
  
  def destroy
    reminder.destroy
    render json: reminder
  end

end
