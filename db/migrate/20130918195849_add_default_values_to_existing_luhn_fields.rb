class AddDefaultValuesToExistingLuhnFields < ActiveRecord::Migration
  def change
    Field.find_all_by_kind('identifier').each do |field|
      next unless field.has_luhn_format?

      luhn_field = field

      collection = luhn_field.collection
      collection_sites = collection.sites
      sites_number = collection_sites.length

      next_luhn_value = luhn_field.default_value_for_create(collection)

      index = 0
      collection_sites.find_each(batch_size: 50) do |site|
        index+= 1

        if site.properties[luhn_field.es_code].blank?
          site.properties[luhn_field.es_code] = next_luhn_value
          site.mute_activities = true
          site.save!
          print "\rGenerating #{index} out of #{sites_number} sites for collection #{collection.id}"

          next_luhn_value = luhn_field.format_implementation.next_luhn(next_luhn_value)
        end
      end
      print "\rDone!"

    end
  end
end
