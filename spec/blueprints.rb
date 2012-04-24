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
  lat { rand(180) - 90 }
  lng { rand(360) - 180 }
  group { false }
end

Layer.blueprint do
  collection
  name
  ord { collection.next_layer_ord }
end

Field.blueprint do
  collection
  layer
  name
  code { Sham.name }
  kind {'text' }
  ord { layer.next_field_ord }
end
