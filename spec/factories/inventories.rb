FactoryGirl.define do
  factory :inventory do
    sequence(:name) { |n| "Inventory no. #{n}" }
    key { (0...20).map { ('a'..'z').to_a[rand(26)] }.join }
    date_generated { 5.days.ago }
    is_skeleton false
    background_job_in_progress false

    factory :skeleton_inventory do
      name 'Test skeleton spreadsheet'
      key 'my-dummy-google-skeleton-spreadsheet-key'
      is_skeleton true
    end
  end
end
