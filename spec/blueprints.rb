require 'machinist/active_record'
require 'sham'
require 'faker'

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  phone_number { rand(1111111..9999999) }
  password { Faker::Name.name }
  username { Faker::Internet.user_name }
  color { "##{rand(255**3).to_s(16)}" }
  sn { |i| i }
end

User.blueprint do
  email
  password
  phone_number
end

Collection.blueprint do
  name
end

Site.blueprint do
  collection
  name
  lat { rand(180) - 90 }
  lng { rand(360) - 180 }
  user { User.make }
end

Layer.blueprint do
  collection
  name
  ord { collection.next_layer_ord }
  user { User.make }
end

Field.blueprint do
  collection
  layer
  name
  code { Sham.name }
  kind {'text' }
  ord { layer.next_field_ord }
end

Activity.blueprint do
end

Threshold.blueprint do
  collection
  ord { Sham.sn }
  color { Sham.color }
end
