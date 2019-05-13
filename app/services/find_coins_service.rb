# frozen_string_literal: true
require 'csv'

class FindCoinsService
  attr_reader :db_adapter, :file_root, :logger
  def initialize(db_adapter:, file_root:, logger: nil)
    @db_adapter = db_adapter
    @file_root = Pathname.new(file_root.to_s)
    @logger = logger || Logger.new(STDOUT)
  end

  def find_coins
    missing_images = []
    dupe_images = []
    same_name_images = []
    coins.ids.each do |coin_number|
      logger.info coin_number

      # Get file path
      obverse_files = Dir.glob(file_root.join("**/#{coin_number}O.*"))
      reverse_files = Dir.glob(file_root.join("**/#{coin_number}R.*"))
      missing_images << ["#{coin_number}O"] if obverse_files.empty?
      missing_images << ["#{coin_number}R"] if reverse_files.empty?

      dupe_obverse_files = find_dupes(obverse_files)[:dupes]
      dupe_reverse_files = find_dupes(reverse_files)[:dupes]
      dupe_images << dupe_obverse_files unless dupe_obverse_files.nil?
      dupe_images << dupe_reverse_files unless dupe_reverse_files.nil?

      same_name_obverse_files = find_dupes(obverse_files)[:same_names]
      same_name_reverse_files = find_dupes(reverse_files)[:same_names]
      same_name_images << same_name_obverse_files unless same_name_obverse_files.nil?
      same_name_images << same_name_reverse_files unless same_name_reverse_files.nil?
    end

    write_csv("tmp/coin-reports/missing_coin_images.csv", missing_images)
    write_csv("tmp/coin-reports/duplicate_images.csv", dupe_images)
    write_csv("tmp/coin-reports/same_name_images.csv", same_name_images)
  end

  def write_csv(file_path, rows)
    return if rows.empty?
    CSV.open(file_path, "wb") do |csv|
      rows.each do |row|
        csv << row
      end
    end
  end

  def find_dupes(file_paths)
    return { same_names: nil, dupes: nil } unless file_paths.count > 1
    checksums = []
    file_paths.each do |path|
      checksums << Digest::MD5.hexdigest(File.read(path))
    end
    return { same_names: nil, dupes: file_paths} if checksums.uniq.count == 1
    return { same_names: file_paths, dupes: nil } if checksums.uniq.count > 1
  end

  def coins
    @coins ||= NumismaticsImportService::Coins.new(db_adapter: db_adapter)
  end
end
