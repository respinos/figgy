# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticArtistChangeSet do
  subject(:change_set) { described_class.new(artist) }
  let(:artist) { NumismaticArtist.new }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:person, :signature, :role, :side)
    end
  end
end
