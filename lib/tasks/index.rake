task :environment

namespace :index do
  desc "Recreate ElasticSearch indices for all collections"
  task :recreate => :environment do
    collections = Collection
    count = collections.count

    print "\rRecreating collection indexes"

    i = 0.0
    collections.find_each do |collection|
      i += 1
      percentage = (100 * (i / count)).round
      print "\rRecreating collection #{i.to_i}/#{count}: %#{percentage}"
      collection.recreate_index
    end

    print "\r#{' ' * 80}"

    print "\rRecreating snapshot indexes"
    snapshot_count = collections.count

    i = 0.0
    Snapshot.find_each do |snapshot|
      i += 1
      percentage = (100 * (i / snapshot_count)).round
      print "\rRecreating snapshot #{i.to_i}/#{snapshot_count}: %#{percentage}"
      snapshot.create_index
    end

    print "\r#{' ' * 80}"
    print "\rDone!"
  end
end
