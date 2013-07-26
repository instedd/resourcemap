namespace :sysadmin do
  namespace :user do
    desc "Confirm a user instead of waiting for her to click the confirmation link"
    task :confirm, [:email] => :environment do |t, args|
      p "Loading user with email #{args[:email]}"
      u = User.find_by_email args[:email]
      unless u
        p "There's not any user with email #{args[:email]}"
        return
      end

      p "Confirming user..."
      u.confirm!
      p "User confirmed!"
    end
  end
end

