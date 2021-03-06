# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::Account::RemovePublicKeyMutation do
  before do
    allow(AuthorizedKeysFile).to receive(:write).and_call_original
  end

  let!(:user) { create :user }
  let(:key_name) { 'stub@localhost' }
  let!(:existing_key) { create :public_key, user: user, name: key_name }

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
    mutation RemovePublicKey($name: String!) {
      removePublicKey(name: $name)
    }
    QUERY
  end

  subject { result }

  context 'User is signed in' do
    let(:current_user) { user }
    before { subject }

    context 'valid key name' do
      let(:variables) { {'name' => key_name} }

      it 'deletes the key' do
        expect(PublicKey.count(user: user, name: key_name)).to eq(0)
      end

      it 'returns true' do
        expect(subject['data']['removePublicKey']).to be(true)
      end

      it 'writes the authorized_keys file' do
        subject
        expect(AuthorizedKeysFile).to have_received(:write)
      end
    end

    context 'invalid key name' do
      let(:variables) { {'name' => "invalid-#{key_name}"} }
      it 'returns an error' do
        expect(subject['errors']).
          to include(include('message' => 'Public key not found'))
      end

      it 'returns no data' do
        expect(subject['data']['removePublicKey']).to be(nil)
      end
    end
  end

  context 'User is not signed in' do
    let(:current_user) { nil }
    let(:variables) { {'name' => 'some-key'} }

    it 'returns an error' do
      expect(subject['errors']).
        to include(include('message' => "You're not authorized to do this"))
    end

    it 'returns no data' do
      expect(subject['data']['removePublicKey']).to be(nil)
    end
  end
end
