# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::Account::SignInMutation,
               stub_abstract_devise_mutation: true do
  let!(:user) { create :user }

  let(:context) { {} }
  let(:variables) do
    {'username' => user.to_param,
     'password' => user.password}
  end

  let(:result) do
    OntohubBackendSchema.execute(
      query_string,
      context: context,
      variables: variables
    )
  end

  let(:query_string) do
    <<-QUERY
    mutation SignIn($username: String!, $password: String!) {
      signIn(username: $username, password: $password) {
        jwt
        me {
          id
        }
      }
    }
    QUERY
  end

  subject { result }

  context 'valid credentials' do
    before do
      allow_any_instance_of(Mutations::Account::SignInResolver).
        to receive(:authenticate).and_return(user)
    end

    it 'returns the JWT' do
      expect(subject['data']['signIn']['jwt']).not_to be_blank
    end

    it 'returns the user' do
      expect(subject['data']['signIn']['me']['id']).to eq(user.to_param)
    end
  end

  context 'invalid credentials' do
    before do
      allow_any_instance_of(Mutations::Account::SignInResolver).
        to receive(:authenticate).and_return(nil)
    end

    it 'returns no data' do
      expect(subject['data']['signIn']).to be(nil)
    end

    it 'returns an error' do
      expect(subject['errors']).
        to include(include('message' => 'Invalid username or password.'))
    end
  end

  context 'already signed in' do
    let(:context) { {current_user: user} }

    it 'returns no data' do
      expect(subject['data']['signIn']).to be(nil)
    end

    it 'returns an error' do
      expect(subject['errors']).
        to include(include('message' => "You're not authorized to do this"))
    end
  end
end
