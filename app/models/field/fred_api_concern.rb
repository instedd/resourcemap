module Field::FredApiConcern
  extend ActiveSupport::Concern

  def identifier?
    metadata && metadata['agency'] && metadata['context']
  end

end
