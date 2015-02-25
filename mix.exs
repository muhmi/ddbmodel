defmodule ExDynamoDbModel.Mixfile do
  use Mix.Project

  def project do
    [ app: :ex_dynamo_db_model,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  defp deps do
    [ { :uuid,              github: "avtobiff/erlang-uuid"      },
      { :jsx,               github: "talentdeficit/jsx", override: true},
      { :erlcloud,          github: "gleber/erlcloud"           }]
  end
end
