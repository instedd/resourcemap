task :environment

namespace :index do
  desc "Recreate ElasticSearch indices for all collections"
  task :recreate => :environment do
    collections = Collection
    count = collections.count

    i = 0.0
    collections.find_each do |collection|
      i += 1
      percentage = (100 * (i / count)).round
      print "\rRecreating collection #{i.to_i}/#{count}: %#{percentage}"
      collection.recreate_index
    end

    print "\r#{' ' * 80}"
    print "\rDone!"
  end
end
