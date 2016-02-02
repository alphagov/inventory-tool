Inventory.delete_all

FactoryGirl.create :skeleton_inventory, name: 'Skeleton spreadsheet', key: GoogleSpreadsheet::SKELETON_KEY
FactoryGirl.create :inventory, name: 'Dummy spreadsheet', date_generated: 5.days.ago
FactoryGirl.create :inventory, name: 'Blank spreadsheet'
