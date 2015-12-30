# == Schema Information
#
# Table name: activity_logs
#
#  id           :integer          not null, primary key
#  inventory_id :integer
#  level        :string(255)
#  message      :text
#  created_at   :datetime
#  updated_at   :datetime
#

FactoryGirl.define do
  factory :activity_log do
    inventory_id  999
    level 'INFO'
    message 'Informational message'
  end

end
