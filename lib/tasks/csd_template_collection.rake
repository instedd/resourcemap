namespace :csd do
  desc "Creates a new CSD-compliant collection sample data suitable for IHE connectathons."
  task :create_collection, [:user_email] => :environment do |t, args|
    user = User.find_by(email: args[:user_email])
    SampleCollectionGenerator.generate user
  end
end