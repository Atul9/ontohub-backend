# frozen_string_literal: true

# Post-processes a finished job that was sent to Hets
class IndexingJob < ApplicationJob
  queue_as 'indexing'

  def perform(*args)
    # This method is implemented in the indexer application.
  end
end
