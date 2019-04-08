# frozen_string_literal: true
class NumismaticAccessionChangeSet < ChangeSet
  delegate :human_readable_type, to: :model

  property :date, multiple: false, required: false
  property :items_number, multiple: false, required: false
  property :type, multiple: false, required: false
  property :cost, multiple: false, required: false
  property :account, multiple: false, required: false
  property :person, multiple: false, required: false
  property :firm, multiple: false, required: false
  property :note, multiple: false, required: false
  property :private_note, multiple: false, required: false
  property :accession_number, multiple: false, required: false
  collection :numismatic_citation, multiple: true, required: false, form: NumismaticCitationChangeSet, populator: :populate_nested_collection, default: []

  validates_with AutoIncrementValidator, property: :accession_number

  # rubocop:disable Metrics/MethodLength
  def primary_terms
    {
      "" => [
        :date,
        :items_number,
        :type,
        :cost,
        :account,
        :person,
        :firm,
        :note,
        :private_note
      ],
      "Citation" => [
        :numismatic_citation
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength

  def build_numismatic_citation
    schema["numismatic_citation"][:nested].new(model.class.schema[:numismatic_citation][[{}]].first)
  end
end
