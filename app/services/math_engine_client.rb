class MathEngineClient
  class Error < StandardError; end

  CALCULATE_PATH = "/calculate"

  def initialize(http_client: HTTParty, base_url: ENV["API_URL"])
    @http_client = http_client
    @base_url = base_url
  end

  def calculate_weights(tickers:, cap: nil, top_n: nil)
    ensure_base_url!

    body = {
      tickers: tickers,
      cap: cap,
      top_n: top_n
    }.to_json

    Rails.logger.info "\nCalling math engine with body: #{body}\n"

    response = http_client.post(
      "#{base_url}#{CALCULATE_PATH}",
      body: body,
      headers: { "Content-Type" => "application/json" }
    )

    raise Error, "Math engine request failed with status #{response.code}" unless response.success?

    Rails.logger.info "Response from math engine: #{response.parsed_response}\n"

    parse_weights(response.parsed_response)
  rescue Error
    raise
  rescue StandardError => e
    raise Error, e.message
  end

  private

  attr_reader :http_client, :base_url

  def ensure_base_url!
    raise Error, "API_URL environment variable is not set" if base_url.blank?
  end

  def parse_weights(payload)
    weights = {}

    payload.fetch("weights").each do |pair|
      weights[pair.fetch("ticker")] = pair.fetch("weight").to_f
    end

    weights
  end
end
