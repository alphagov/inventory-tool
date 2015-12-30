require 'rails_helper'

RSpec.describe ActivityLogsController, type: :controller do

  describe "GET #index" do
    it "assigns all activity_logs as @activity_logs" do
      activity_log = create :activity_log
      get :index
      expect(assigns(:activity_logs)).to eq([activity_log])
    end
  end

  describe "GET #show" do
    it "assigns the all the non debug activity logs for inventory n to @activity_logs" do
      logs = []
      inv = create :inventory
      %w{INFO WARN DEBUG ERROR}.each do |level|
        [inv.id, inv.id + 100].each do |inv_id|
          logs << create(:activity_log, level: level, inventory_id: inv_id)
        end
      end
      get :show, {:id => inv.id}
      expect(assigns(:inventory)).to eq inv
      expect(assigns(:activity_logs).size).to eq 4
      expect(assigns(:activity_logs).map(&:inventory_id)).to eq( [inv.id, inv.id, inv.id, inv.id] )
      expect(assigns(:activity_logs).map(&:level)).to eq(%w{ ERROR DEBUG WARN INFO })
    end
  end
end
