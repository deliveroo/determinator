require 'determinator/version'
require 'determinator/control'
require 'determinator/feature'
require 'determinator/target_group'
require 'determinator/feature_store'

module Determinator
  # The storage engine is used to perma-cache features as they are changed by the originating service.
  # The `FeatureStore` _also_ implements an in-memory short-lived cache on top of this.
  def self.configure(initialize_from:, retrieval:, storage:)
    feature_store = FeatureStore.new(
      storage: storage,
      retrieval: retrieval
    )
  end
end
