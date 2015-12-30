namespace :db do
  namespace :log do
    desc 'prunes DEBUG and out-of-date ActivityLog records from the datbase'
    task :prune => :environment do
      DatabasePruner.new.run
    end
  end
end
