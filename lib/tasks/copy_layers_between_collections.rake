require 'net/http'

namespace :layers do
  desc "Export collection's layers as json to a file"
  task :export_layers , [:user, :password, :server, :collection_id, :out_file] => :environment do |t, args|

  	def abort_with(message)
  		puts "Usage: rake layers:export_layers['{user}','{password}','{server}',{collection_id}, '{out-file-name}']"
  		puts "Example: rake layers:export_layers['user@mail.com','12345','resourcemap.instedd.org',23, 'layers_23']"
  		abort "Error: #{message}"
  	end

  	puts "Calling export_layers with arguments: #{args}"

  	abort_with "Invalid arguments" unless args.to_hash.keys.length == 5

  	uri = URI.parse("http://#{args[:server]}/collections/#{args[:collection_id]}/layers.json") rescue (abort_with "Could not parse URL http://#{args[:server]}/collections/#{args[:collection_id]}/layers.json")
		req = Net::HTTP::Get.new(uri.request_uri)
		req.basic_auth "#{args[:user]}", "#{args[:password]}"

		res = Net::HTTP.start(uri.hostname, uri.port) {|http|
  		http.request(req)
		}

		if !res.is_a?(Net::HTTPSuccess)
			puts "HTTP error code #{res.code}"
			puts res.message
			abort_with "HTTP error"
		else
			File.open("#{args[:out_file]}.json", "w+") do |f|
  			f.write(res.body)
			end
			puts "Done!"
			puts "Output saved into #{args[:out_file]}.json file"
		end
  end

  desc "Import layers from json file into collection"
  task :import_layers, [:input_file, :target_collection, :user_email] => :environment do |t, args|

  	def abort_with(message)
  		puts "Usage: rake layers:import_layers['{input_file}','{target_collection_id},'{admin_user_email}']"
  		puts "Example: rake layers:import_layers['layers_23.json',58,'admin@email.com']"
  		abort message
  	end

  	puts "Calling import_layers with arguments: #{args}"

  	abort_with "Invalid arguments" unless args.to_hash.keys.length == 3

  	json_object = JSON.parse( IO.read("#{args[:input_file]}")) rescue (abort_with "Could not read file #{args[:input_file]}")
		json_string = json_object.to_json

		c = Collection.find args[:target_collection]
		abort_with "Collection with id #{args[:target_collection]} not found" unless c
		u = User.find_by_email args[:user_email]
		abort_with "User with email #{args[:user_email]} not found" unless u

		abort "Error: Collection already contains layers. Layers must be empty in order to complete the import" unless c.layers.count == 0

		if u.admins? c
			c.import_schema(json_string,u)
			puts "Done!"
		else
			abort "Error: User is not collection's admin"
		end

  end

end
