class RecalculteLuhnValuesWithTheNewAlgorithm < ActiveRecord::Migration

  class Site < ActiveRecord::Base
    self.table_name = "sites"
    serialize :properties, Hash

  end

  class Collection < ActiveRecord::Base
    self.table_name = "collections"

    has_many :sites
  end


  class Field < ActiveRecord::Base
    self.table_name = "fields"
    belongs_to :collection
    serialize :config, MarshalZipSerializable

    def es_code
      id.to_s
    end

    def has_luhn_format?
      config && config['format'] == "Luhn"
    end

    def compute_luhn_verifier(str)
      # Algorithm: http://en.wikipedia.org/wiki/Luhn_algorithm
      # Verifier: http://www.ee.unb.ca/cgi-bin/tervo/luhn.pl
      n = str.length - 1
      even = true
      sum = 0
      while n >= 0
        digit = str[n].to_i

        if even
          if digit < 5
            sum += digit * 2
          else
            sum += 1 + (digit - 5) * 2
          end
        else
          sum += digit
        end

        even = !even

        n -= 1
      end

      (10 - sum) % 10
    end

  end

  def up
    Field.find_all_by_kind('identifier').each do |field|
      next unless field.has_luhn_format?

      luhn_field = field

      collection = luhn_field.collection
      collection_sites = collection.sites

      print "Recalculating luhn ckeck for collection #{collection.id}"

      collection_sites.find_each(batch_size: 50) do |site|

        value = site.properties[luhn_field.es_code]

        if !value.blank?
          value =~ /(\d\d\d\d\d\d)\-(\d)/
          verifier = field.compute_luhn_verifier($1)
          site.properties[luhn_field.es_code] = "#{$1}-#{verifier}"
          site.save!
        end

      end
      print "\rDone!"
    end
  end
end
