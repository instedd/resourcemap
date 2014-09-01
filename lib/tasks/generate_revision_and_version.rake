namespace :deploy do
  desc "Generate REVISION and VERSION files with the changeset and date of the current revision"
  task :generate_revision_and_version, [:version] do |t, args|
    revision = `git describe --always`

   File.open('REVISION', "w+") do |f|
      f.write(revision)
    end

    File.open('VERSION', "w+") do |f|
      f.write(args[:version].presence || revision)
    end
  end
end
