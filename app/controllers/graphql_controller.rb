# frozen_string_literal: true

# Controller for the GraphQL API endpoint
class GraphqlController < ApplicationController
  # rubocop:disable Metrics/MethodLength
  def execute
    variables = ensure_hash(params[:variables])
    query = params[:query]
    context = {
      current_user: current_user,
    }
    result = OntohubBackendSchema.execute(
      query,
      variables: variables,
      context: context
    )
    render json: result
  end
  # rubocop:enable Metrics/MethodLength

  private

  # Handle form data, JSON body, or a blank value
  # rubocop:disable Metrics/MethodLength
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
  # rubocop:enable Metrics/MethodLength
end