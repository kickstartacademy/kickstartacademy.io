$: << File.dirname(__FILE__) + '/lib'
ENV["RACK_ENV"] = 'test'

require 'app'
require 'test/unit'
require 'rack/test'

describe "integration testing" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  [
    '/',
    '/blog',
    '/blog/archive',
    '/courses',
    '/courses/bdd-kickstart',
    '/courses/continuous-delivery-kickstart',
    '/courses/practical-object-oriented-design',
    '/dates',
    '/team',
    '/coaching',
    '/thanks',
    '/remote',
    '/in-house-courses/bdd',
    '/in-house-courses/cd',
    '/in-house-courses/poodr',
  ].each do |page|
    it "returns #{page} with a non failure code" do
      get page
      expect(last_response).to be_ok
    end
  end

  require 'webmock/rspec'
  describe "web hooks" do

    before do
      WebMock.disable_net_connect!
      stub_request(:post, "https://kickstartacademy.slack.com/services/hooks/incoming-webhook?token=tP9YYqIj1pS3yenCgM5yTy0Z")
    end

    let(:payload) {
      {
        "name" => "Paul Campbell",
        "first_name" => "Paul",
        "last_name" => "Campbell",
        "email" => "funconf@gmail.com",
        "reference" => "1i5nfwf2t",
        "price" => "1.00",
        "slug" => "1i5nfwf2t24",
        "state_name" => "void",
        "gender" => "male",
        "release_price" => "1.00",
        "discount_code_used" => "",
        "release" => "AwesomeConf ticket",
        "custom" => "Awesome!",
        "registration_id" => "bdtyap3hguq",
        "answers" => [ ]
      }.to_json
    }
    let(:headers) { { 'X-Webhook-Name' => 'ticket.created' } }

    it "accepts incoming ticket information from tito" do
      post '/integrations/tito/ticket', payload, headers

      expect( last_response ).to be_ok
    end

    it "forwards the message to slack" do
      slack_webhook_payload = {
        "channel" => "#general",
        "username" => "kickstartac",
        "icon_emoji" => ":rocket:",
        "text" => "AwesomeConf ticket created for Paul Campbell"
      }

      post '/integrations/tito/ticket', payload, headers

      expect( a_request(:post, ENV["SLACK_WEBHOOK_URL"])).to have_been_made
    end
  end
end

