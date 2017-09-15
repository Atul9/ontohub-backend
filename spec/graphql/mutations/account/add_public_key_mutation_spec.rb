# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'addPublicKey mutation' do
  let!(:user) { create :user }

  let(:context) { {current_user: current_user} }
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
    mutation AddPublicKey($key: String!) {
      addPublicKey(key: $key) {
        key
        name
      }
    }
    QUERY
  end

  subject { result }

  context 'User is signed in' do
    let(:current_user) { user }
    context 'valid key' do
      let(:public_key_blueprint) { build(:public_key) }
      let(:key) { public_key_blueprint.key }
      let(:key_name) { public_key_blueprint.name }
      let(:variables) { {'key' => "#{key} #{key_name}"} }

      context 'new name' do
        it 'returns the key' do
          expect(subject['data']['addPublicKey']['key']).to eq(key)
        end

        it 'returns the name' do
          expect(subject['data']['addPublicKey']['name']).
            to eq(key_name)
        end
      end

      context 'existing name' do
        before do
          create :public_key, user: user, name: key_name
        end

        it 'returns no key' do
          expect(subject['data']['addPublicKey']).to be(nil)
        end

        it 'returns an error' do
          expect(subject['errors']).
            to include(include('message' => 'name is already taken'))
        end
      end
    end

    context 'invalid key' do
      let(:variables) { {'key' => 'badkey'} }

      it 'returns no key' do
        expect(subject['data']['addPublicKey']).to be(nil)
      end

      it 'returns an error' do
        expect(subject['errors']).
          to include(include('message' => 'key is invalid'),
                     include('message' => 'name is not present'))
      end
    end
  end
end