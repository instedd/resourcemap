namespace :deploy do
  desc "Generate REVISION and VERSION files with the changeset and date of the current revision"
  task :generate_revision_and_version do
    output = `hg log -l1`
    mercurial_info = Hash[output.split("\n").map { |line| line.split(':', 2).map(&:strip) }]

   File.open('REVISION', "w+") do |f|
      f.write(mercurial_info["changeset"])
    end

    File.open('VERSION', "w+") do |f|
      f.write(Date.parse(mercurial_info["date"]).strftime("%b %d %Y"))
    end
  end
end