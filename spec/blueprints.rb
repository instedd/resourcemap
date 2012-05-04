require 'machinist/active_record'
require 'sham'
require 'faker'

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  password { Faker::Name.name }
  username { Faker::Internet.user_name }
  color { "##{rand(255**3).to_s(16)}" }
  sn { |i| i }
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
  lat { rand(180) - 90 }
  lng { rand(360) - 180 }
  group { false }
end

Layer.blueprint do
  collection
  name
end

Field.blueprint do
  collection
  layer
  name
  code { Sham.name }
  kind {'text' }
end

Threshold.blueprint do
  collection
  priority { Sham.sn }
  color { Sham.color }
end
