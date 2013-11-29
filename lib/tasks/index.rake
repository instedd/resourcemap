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
      next if snapshot.collection.nil?
      snapshot.recreate_index
    end

    print "\r#{' ' * 80}"
    print "\rDone!"
  end

  desc "Recreate ElasticSearch indices for all collections"
  task :recreate_one, [:collection_id] => :environment do |t, args|
    collection = Collection.find args[:collection_id].to_i
    puts "\rRecreating index for collection #{collection.name}"

    collection.recreate_index

    snapshot_count = collection.snapshots.count

    collection.snapshots.each_with_index do |snapshot, i|
      percentage = (100.0 * (i / snapshot_count)).round
      print "\rRecreating snapshot #{i.to_i}/#{snapshot_count}: %#{percentage}"
      snapshot.recreate_index
    end

    puts "Done!"
  end
end
