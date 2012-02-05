require 'machinist/active_record'
require 'sham'
require 'faker'

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  password { Faker::Name.name }
  username { Faker::Internet.user_name }
end

User.blueprint do
  email
  password
end

Collection.blueprint do
  name
end

Site.blueprint do
  collection
  name
  lat { rand * 90 - 180 }
  lng { rand * 180 - 360 }
  folder { false }
end
