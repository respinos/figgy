# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticAttributeChangeSet do
  subject(:change_set) { described_class.new(attribute) }
  let(:attribute) { NumismaticAttribute.new }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:description, :name)
    end
  end
end
