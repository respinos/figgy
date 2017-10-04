# frozen_string_literal: true
class CompositeQueryAdapter
  class EphemeraVocabularyCompositeQueryAdapter < CompositeQueryAdapter
    class_attribute :query_adapter_class
    self.query_adapter_class = QueryAdapter::EphemeraVocabularyQueryAdapter
    class_attribute :persistence_adapter_class
    self.persistence_adapter_class = QueryAdapter::PersistenceAdapter::EphemeraVocabularyPersistenceAdapter
  end
end
