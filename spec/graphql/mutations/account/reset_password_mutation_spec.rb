# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::Account::ResetPasswordMutation,
  type: :mailer, no_transaction: true, stub_abstract_devise_mutation: true do
  let!(:user) { create :user }
  let!(:token) { user.send_reset_password_instructions }
  let(:old_password) { user.password }
  let(:new_password) { "new-#{user.password}" }

  let(:context) { {} }
  let(:variables) { {'password' => new_password, 'token' => token} }

  let(:result) do
    perform_enqueued_jobs do
      OntohubBackendSchema.execute(
        query_string,
        context: context,
        variables: variables
      )
    end
  end

  let(:query_string) do
    <<-QUERY
    mutation ResetPassword($password: String!, $token: String!) {
      resetPassword(password: $password, token: $token) {
        jwt
        me {
          id
        }
      }
    }
    QUERY
  end

  subject { result }

  before do
    UsersMailer.deliveries.clear
    queue_adapter.performed_jobs = []
    subject
  end

  context 'valid token' do
    it 'returns the JWT' do
      expect(subject['data']['resetPassword']['jwt']).not_to be_blank
    end

    it 'returns the user' do
      expect(subject['data']['resetPassword']['me']['id']).to eq(user.to_param)
    end

    it_behaves_like 'a password has been reset email sender'

    it 'makes it impossible to sign in with the old password' do
      expect(user.reload.valid_password?(old_password)).to be(false)
    end

    it 'makes it possible to sign in with the new password' do
      expect(user.reload.valid_password?(new_password)).to be(true)
    end
  end

  context 'invalid token' do
    let(:variables) { {'password' => new_password, 'token' => "bad-#{token}"} }

    it 'returns no data' do
      expect(subject['data']['resetPassword']).to be(nil)
    end

    it 'returns an error' do
      expect(subject['errors']).
        to include(include('message' => 'Invalid reset password token.'))
    end
  end
end
