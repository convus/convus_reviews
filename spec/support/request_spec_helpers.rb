shared_context :logged_in_as_user do
  let(:current_user) { FactoryBot.create(:user) }

  before { sign_in current_user }
end

shared_context :logged_in_as_administrator do
  let(:current_user) { FactoryBot.create(:user_admin) }

  before { sign_in current_user }
end

RSpec.shared_context :test_csrf_token do
  before { ActionController::Base.allow_forgery_protection = true }
  after { ActionController::Base.allow_forgery_protection = false }
end

# Request spec helpers that are included in all request specs via Rspec.configure (rails_helper)
module RequestSpecHelpers
  def json_headers
    {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}
  end

  def json_result
    r = JSON.parse(response.body)
    r.is_a?(Hash) ? r.with_indifferent_access : r
  end

  def expect_turbo_stream_response
    pp response.media_type
    expect(response.media_type).to eq Mime[:turbo_stream]
  end
end
