require 'google/apis/sheets_v4'

class SpreadsheetService
  def self.get_data(spreadsheet_id)
    service = Google::Apis::SheetsV4::SheetsService.new
    service.key = Settings.google_sheet_api_key

    range = SpreadsheetService.get_range(spreadsheet_id)
    begin
      response = service.get_spreadsheet_values(spreadsheet_id, range)
    rescue Exception => e
      Rails.logger.error e.message + "\n" + e.backtrace.join("\n")
      raise ActionController::BadRequest.new(), e.message()
    end

    response.values
  end

  def self.get_range(spreadsheet_id)
    service = Google::Apis::SheetsV4::SheetsService.new
    service.key = Settings.google_sheet_api_key

    begin
      sheet = service.get_spreadsheet(spreadsheet_id)
      range = sheet.sheets[0].properties.title
      range
    rescue Exception => e
      Rails.logger.error e.message + "\n" + e.backtrace.join("\n")
      raise ActionController::BadRequest.new(), e.message()
    end
  end
end
