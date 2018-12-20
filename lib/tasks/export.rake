# frozen_string_literal: true
namespace :export do
  desc "Exports an object to disk in a BagIt bag"
  task bag: :environment do
    id = ENV["ID"]
    abort "usage: rake export:bag ID=[object id]" unless id

    ExportBagJob.perform_now(id)
  end

  desc "Exports Cicognara resource metadata to CSV"
  task cicognara: :environment do
    coll = ENV["COLL"]
    abort "usage: rake export:cicognara COLL=[collection id]" unless coll

    CSV do |csv|
      csv << CicognaraCSV.headers
      CicognaraCSV.values(coll).each do |row|
        csv << row
      end
    end
  end
end
