class Capybara::Session
  
  def save_screenshot_with_path(path)
    save_screenshot_without_path(File.join(Rails.root, "spec/integration/screenshots/", path))
  end
  alias_method_chain :save_screenshot, :path

  def attach_file_with_path(locator, path)
    attach_file_without_path(locator, File.join(Rails.root, "spec/integration/uploads/", path))
  end
  alias_method_chain :attach_file, :path

  def send_key(jquery_selector, key)
    script = "var e = $.Event('keydown', { keyCode: #{key} }); $('#{jquery_selector}').trigger(e); "
    execute_script script
  end

end
