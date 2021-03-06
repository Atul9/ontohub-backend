# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'me query' do
  subject { create :user }
  let(:organization) { create :organization }

  before do
    organization.add_member(subject)
  end

  let(:context) { {} }
  let(:variables) { {} }

  let(:result) do
    OntohubBackendSchema.execute(
      query_string,
      context: context,
      variables: variables
    )
  end

  let(:query_string) do
    <<-QUERY
    query Me {
      me {
        id
        displayName
        email
        emailHash
        organizationMemberships {
          organization {
            id
          }
          member {
            id
          }
          role
        }
      }
    }
    QUERY
  end

  context 'signed in' do
    let(:context) { {current_user: subject} }
    it 'returns the user fields' do
      user = result['data']['me']
      expect(user).to include(
        'id' => subject.slug,
        'displayName' => subject.display_name,
        'email' => subject.email,
        'emailHash' => subject.email_hash,
        'organizationMemberships' => [
          {'member' => {'id' => subject.slug},
           'organization' => {'id' => organization.slug},
           'role' => 'read'},
        ]
      )
    end
  end

  context 'not signed in' do
    it 'returns null' do
      expect(result['data']['me']).to be(nil)
    end
  end
end
