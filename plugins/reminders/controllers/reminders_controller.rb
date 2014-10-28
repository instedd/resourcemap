class RemindersController < ApplicationController
  # before_filter :authenticate_user!
  before_filter :authenticate_collection_user!

  def index
    respond_to do |format| format.html do
        show_collection_breadcrumb
        add_breadcrumb "Properties", collection_path(collection)
        add_breadcrumb "Reminders", collection_reminders_path(collection)
      end
      format.json { render_json(reminders.as_json(include: [:repeat], methods: [:reminder_date], except: [:schedule])) }
    end
  end

  def create
    reminder = reminders.new params[:reminder].except(:sites)
    reminder.sites = Site.select("id, collection_id, name, properties").find params[:reminder][:sites] if params[:reminder][:sites]
    reminder.save!
    render_json reminder
  end

  def update
    reminder = reminders.find params[:id]
    reminder.update_attributes! params[:reminder].except(:sites)
    reminder.sites = Site.select("id, collection_id, name, properties").find params[:reminder][:sites] if params[:reminder][:sites]

    reminder.save!
    render_json reminder
  end

  def destroy
    reminder.destroy
    render_json reminder
  end

  def set_status
    reminder.update_attribute :status, params[:status]
    render_json reminder
  end
end
