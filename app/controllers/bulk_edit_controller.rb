# frozen_string_literal: true
class BulkEditController < ApplicationController
  include Blacklight::SearchHelper

  def resources_edit
    (solr_response, _document_list) = search_results(q: params["q"], f: params["f"])
    @resources_count = solr_response["response"]["numFound"]
  end

  def resources_update
    args = {}.tap do |hash|
      hash[:mark_complete] = (params["mark_complete"] == "1")
    end
    batches = prepare_batches
    batches.each do |ids|
      BulkUpdateJob.perform_later(ids: ids, args: args)
    end
    resources_count = batches.map(&:count).reduce(:+)
    flash[:notice] = "#{resources_count} resources were queued for bulk update."
    redirect_to root_url
  end

  private

    # Prepare / execute the search and process into id arrays
    def prepare_batches
      builder_params = { q: params["search_params"]["q"], f: params["search_params"]["f"] }
      builder = search_builder.with(builder_params)
      builder.rows = params["batch_size"] || 50
      [].tap do |batches|
        loop do
          response = repository.search(builder)
          batches << response.documents.map(&:id)
          break if (builder.page * builder.rows) >= response["response"]["numFound"]
          builder.start = builder.rows * builder.page
          builder.page += 1
        end
      end
    end
end
