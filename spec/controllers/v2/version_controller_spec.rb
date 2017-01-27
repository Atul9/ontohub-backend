# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V2::VersionController do
  describe 'GET show' do
    before do
      stub_const('Version::VERSION', '0.0.0-12-gabcdefg')
    end
    before { get :show }
    it { expect(response).to have_http_status(:ok) }
    it { expect(response).to match_response_schema('v2', 'jsonapi') }
    it { expect(response).to match_response_schema('v2', 'version_show') }
  end
end