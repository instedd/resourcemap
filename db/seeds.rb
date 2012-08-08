# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Repeat.find_or_create_by_name(name: "from Monday to Friday", order: 1, rule: IceCube::Rule.weekly.day(:monday, :tuesday, :wednesday, :thursday, :friday))
Repeat.find_or_create_by_name(name: "Everyday", order: 2, rule: IceCube::Rule.daily)
Repeat.find_or_create_by_name(name: "Every week", order: 3, rule: IceCube::Rule.weekly)
Repeat.find_or_create_by_name(name: "Every 2 weeks", order: 4, rule: IceCube::Rule.weekly(2))
Repeat.find_or_create_by_name(name: "Every month", order: 5, rule: IceCube::Rule.monthly)
