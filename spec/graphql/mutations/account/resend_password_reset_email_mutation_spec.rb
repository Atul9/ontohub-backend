# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::Account::ResendPasswordResetEmailMutation,
  type: :mailer, no_transaction: true, stub_abstract_devise_mutation: true do
  let!(:user) { create :user }

  let(:context) { {} }
  let(:variables) { {} }

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
    mutation ResendPasswordResetEmail($email: String!) {
      resendPasswordResetEmail(email: $email)
    }
    QUERY
  end

  subject { result }

  before do
    queue_adapter.performed_jobs = []
    UsersMailer.deliveries.clear
    subject
  end

  context 'User exists' do
    let(:variables) { {'email' => user.email} }

    it 'returns true' do
      expect(subject['data']['resendPasswordResetEmail']).to be(true)
    end
    it_behaves_like 'a password reset email sender'
  end

  context 'User does not exist' do
    let(:variables) { {'email' => "bad-#{user.email}"} }

    it 'returns true' do
      expect(subject['data']['resendPasswordResetEmail']).to be(true)
    end

    it 'does not send an email' do
      expect(performed_jobs).to be_empty
      expect(UsersMailer.deliveries).to be_empty
    end
  end
end
