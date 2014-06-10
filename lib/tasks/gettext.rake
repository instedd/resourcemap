namespace :gettext do
  def files_to_translate
    Dir.glob("{app,lib,config,locale,plugins}/**/*.{rb,erb,haml,slim,rhtml,coffee}")
  end

  desc "Find coffee"
  task :find_coffee do
    require 'gettext_i18n_rails_js/js_and_coffee_parser'
  end

  Rake::Task["gettext:find"].enhance [:find_coffee]
end
