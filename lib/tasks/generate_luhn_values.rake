namespace :sites do
  desc "Generate valid luhn values to all collection sites for a particular Luhn Identifier Field.
  This will generate values for all the collection sites that do not have a value already.
  This might take a while, since we need to ensuere the uniqueness for each value inside the collection."

  task :generate_luhn_values , [:collection_id, :luhn_field_id] => :environment do |t, args|

    def abort_with(message)
      puts "Usage: rake sites:generate_luhn_values[{collection_id},'{luhn_field_id}']"
      puts "Example: rake sites:generate_luhn_values[23, 123]"
      abort "Error: #{message}"
    end

    puts "Calling generate_luhn_values with arguments: #{args}"

    abort_with "Invalid arguments" unless args.to_hash.keys.length == 2

    collection = Collection.find args[:collection_id].to_i
    abort_with "Collection with id #{args[:collection_id]} was not found." unless collection

    luhn_field_array = collection.fields.where id: args[:luhn_field_id]
    abort_with "Field with id #{args[:luhn_field_id]} was not found in the collection's layers." unless luhn_field_array.length > 0
    luhn_field = luhn_field_array.first

    abort_with "Field is not an Identifier with Luhn format." unless luhn_field.kind == 'identifier' && luhn_field.has_luhn_format?

    collection_sites = collection.sites
    sites_number = collection_sites.length

    Site.transaction do
      collection_sites.each_with_index do |site, index|
        print "\rGenerating #{index} out of #{sites_number} sites"
        next if !site.properties[luhn_field.es_code].blank?

        next_luhn_value = luhn_field.default_value_for_create(collection)
        site.properties[luhn_field.es_code] = next_luhn_value
        site.mute_activities = true
        site.save!
      end
    end
    print "\rDone!"

  end

end
