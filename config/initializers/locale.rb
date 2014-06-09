module Locales

  def available
    ResourceMap::Application.config.available_locales
  end

  def default
    ResourceMap::Application.config.default_locale
  end

  def many?
    available.count > 1
  end

  extend self

end
