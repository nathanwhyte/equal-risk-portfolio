module CallLambda
  extend ActiveSupport::Concern

  def dev_call_lambda(tickers)
    url = "http://localhost:9000/2015-03-31/functions/function/invocations"

    event = {
      "httpMethod": "GET",
      "path": "/calculate",
      "requestContext": {
        "tickers": tickers
      },
      "version": "1.0"
    }

    response = HTTParty.post(
      url,
      body: event.to_json,
      headers: {
        "Content-Type" => "application/json"
      },
    )

    # looks like [{"ticker":"AAPL","weight":"7.41"},{"ticker":"MSFT","weight":"12.34"}]
    weights_json = JSON.parse(JSON.parse(response.body)["body"])["weights"]

    weights = {}

    # format to look like [{ "AAPL" => "7.41", "MSFT" => "12.34" }]
    weights_json.each do |pairing|
      ticker = pairing["ticker"]
      weight = pairing["weight"]
      weights[ticker.to_sym] = weight
    end

    weights
  end

  def call_lambda(tickers)
    if Rails.env.development?
      return dev_call_lambda(tickers)
    end

    _ = AwsLambdaClient.invoke(
      function_name: "equal-risk-lambda",
      payload: JSON.generate(
        {
          "httpMethod": "GET",
          "path": "/",
          "requestContext": {
            "variableName": "test"
          },
          "version": "1.0"
        }
      ),
    )
  end
end
