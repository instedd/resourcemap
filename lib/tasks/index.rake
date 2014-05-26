task :environment

def recycle_console
  print "\r#{' ' * 120}"
end

def recreate_many(collections)
  count = collections.count

  print "\rRecreating collection indexes"

  i = 0.0
  collections.find_each do |collection|      
    i += 1
    percentage = (100 * (i / count)).round
    recycle_console
    print "\rRecreating collection(id: #{collection.id}, name: #{collection.name}) #{i.to_i}/#{count}: #{percentage}%"
    collection.recreate_index
  end

  print "\rRecreating snapshot indexes"
  snapshot_count = collections.count

  i = 0.0
  Snapshot.find_each do |snapshot|
    i += 1
    percentage = (100 * (i / snapshot_count)).round    
    next if snapshot.collection.nil?
    recycle_console
    print "\rRecreating snapshot(id: #{snapshot.id}, collection_id: #{snapshot.collection.id}) #{i.to_i}/#{snapshot_count}: #{percentage}%"
    snapshot.recreate_index
  end

  recycle_console
  print "\rDone!"   
end

namespace :index do
  desc "Recreate ElasticSearch indices for all collections"
  task :recreate => :environment do
    collections = Collection
    recreate_many collections
  end

  desc "Recreate ElasticSearch index for a given collection"
  task :recreate_one, [:collection_id] => :environment do |t, args|
    collection = Collection.find args[:collection_id].to_i
    puts "\rRecreating index for collection #{collection.name}"

    collection.recreate_index

    snapshot_count = collection.snapshots.count

    collection.snapshots.each_with_index do |snapshot, i|
      percentage = (100.0 * (i / snapshot_count)).round
      print "\rRecreating snapshot #{i.to_i}/#{snapshot_count}: #{percentage}%"
      snapshot.recreate_index
    end

    puts "Done!"
  end

  desc "Recreate ElasticSearch indices for collections whose id is bigger than the param"
  task :recreate_from, [:collection_id] => :environment do |t, args|
    collections = Collection.where("id >= ?", args[:collection_id].to_i)
    recreate_many collections
  end

  desc "Recreate ElasticSearch index for a given snapshot"
  task :recreate_one_snapshot, [:snapshot_id] => :environment do |t, args|
    snapshot = Snapshot.find(args[:snapshot_id].to_i)
    print "\rRecreating snapshot(id: #{snapshot.id}, collection_id: #{snapshot.collection.id})"
    snapshot.recreate_index
  end
end
