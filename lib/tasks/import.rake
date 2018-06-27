# frozen_string_literal: true
namespace :import do
  desc "Re-run characterization for an object"
  task recharacterize: :environment do
    id = ENV["ID"]
    abort "usage: rake import:recharacterize ID=figgyid" unless id

    RecharacterizeJob.set(queue: :low).perform_later(id)
  end

  desc "Ingest a METS file."
  task mets: :environment do
    file = ENV["FILE"]
    user = User.find_by_user_key(ENV["USER"]) if ENV["USER"]
    user = User.all.select(&:admin?).first unless user

    abort "usage: rake import:mets FILE=/path/to/file.mets [USER=aperson]" unless file && File.file?(file)

    @logger = Logger.new(STDOUT)
    @logger.info "ingesting as: #{user.user_key} (override with USER=foo)"
    @logger.info "queuing job to ingest file: #{file}"

    IngestMETSJob.set(queue: :low).perform_later(file, user)
  end
end
