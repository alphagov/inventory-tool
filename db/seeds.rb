# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.firs

Inventory.delete_all

FactoryGirl.create :skeleton_inventory, name: 'Skeleton spreadsheet', key: '17c-_p0FqQbr0s3ITVQbhp9KG0iI82TEaFO-RfHFsIME'
FactoryGirl.create :inventory, name: 'Dummy spreadsheet', date_generated: 5.days.ago
FactoryGirl.create :inventory, name: 'Virgin spreadsheet'
