module CapybaraSessionHelpers
  def save_screenshot(path)
    super File.join(Rails.root, "spec/integration/screenshots/", path)
  end

  def attach_file(locator, path)
    super locator, File.join(Rails.root, "spec/integration/uploads/", path)
  end
end

class Capybara::Session
  prepend CapybaraSessionHelpers

  def send_key(jquery_selector, key)
    script = "var e = $.Event('keydown', { keyCode: #{key} }); $('#{jquery_selector}').trigger(e); "
    execute_script script
  end
end
