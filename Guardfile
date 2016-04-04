# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :jasmine, server_mount: '/' do
  watch(%r{^(plugins/(.+)/)?spec/javascripts/.*(?:_s|S)pec\.(coffee|js)$})
  watch(%r{app/assets/javascripts/(.+?)\.(js\.coffee|js|coffee)(?:\.\w+)*$}) do |m|
    "spec/javascripts/#{ m[1] }_spec.#{ m[2] }"
  end
end
