require "test_helper"

class MathEngineClientTest < ActiveSupport::TestCase
  StubResponse = Struct.new(:code, :parsed_response, :success?)

  class StubHttpClient
    attr_reader :last_request

    def initialize(response)
      @response = response
    end

    def post(url, body:, headers:)
      @last_request = { url: url, body: body, headers: headers }
      @response
    end
  end

  def test_returns_weights_from_successful_response
    response = StubResponse.new(
      200,
      {
        "weights" => [
          { "ticker" => "AAPL", "weight" => 0.6 },
          { "ticker" => "MSFT", "weight" => 0.4 }
        ]
      },
      true
    )
    http_client = StubHttpClient.new(response)

    client = MathEngineClient.new(http_client: http_client, base_url: "http://example.com")
    result = client.calculate_weights(tickers: %w[AAPL MSFT], cap: 0.5, top_n: 10)

    assert_equal({ "AAPL" => 0.6, "MSFT" => 0.4 }, result)
    assert_equal "http://example.com/calculate", http_client.last_request[:url]

    body = JSON.parse(http_client.last_request[:body])
    assert_equal %w[AAPL MSFT], body["tickers"]
    assert_equal 0.5, body["cap"]
    assert_equal 10, body["top_n"]
    assert_equal "application/json", http_client.last_request[:headers]["Content-Type"]
  end

  def test_raises_error_when_response_unsuccessful
    response = StubResponse.new(500, {}, false)
    http_client = StubHttpClient.new(response)
    client = MathEngineClient.new(http_client: http_client, base_url: "http://example.com")

    error = assert_raises(MathEngineClient::Error) do
      client.calculate_weights(tickers: %w[AAPL MSFT])
    end

    assert_match(/Math engine request failed/, error.message)
  end

  def test_raises_error_when_base_url_missing
    client = MathEngineClient.new(base_url: nil)

    error = assert_raises(MathEngineClient::Error) do
      client.calculate_weights(tickers: %w[AAPL])
    end

    assert_match(/API_URL/, error.message)
  end
end
