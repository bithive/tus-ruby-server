require "test_helper"
require "rack/test_app"

describe Tus::Server do
  before do
    @server = Class.new(Tus::Server)
    @storage = @server.opts[:storage] = Tus::Storage::Filesystem.new("data")

    @hooks = MiniTest::Mock.new
    @server.opts[:hook_module] = @hooks

    builder = Rack::Builder.new
    builder.use Rack::Lint
    builder.run Rack::URLMap.new("/files" => @server)

    @app = Rack::TestApp.wrap(builder)
  end

  after do
    FileUtils.rm_rf("data")
  end

  def request(verb)
    @app.send(verb, '/files', headers: { 'Tus-Resumable' => '1.0.0',
      'Upload-Length' => '100'})
  end

  it "calls the creation hooks" do
    @hooks.expect :pre_create,  nil, [nil, Tus::Info]
    @hooks.expect :post_create, nil, [String, Tus::Info]

    response = request(:POST)

    assert_mock @hooks
  end

  it "responds with errors" do
    error = { status: 405, message: 'Method Not Allowed' }
    @hooks.expect(:pre_create, [ error[:status], error[:message] ], [nil, Tus::Info])

    response = request(:POST)

    assert_mock @hooks
    assert_equal error[:status], response.status
  end
end
