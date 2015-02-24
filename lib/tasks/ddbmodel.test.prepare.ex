Code.require_file "../../../test/test_helper.exs", __ENV__.file

defmodule Mix.Tasks.Test.Prepare do
  use Mix.Task

  @shortdoc "Prepares environment for testing"

  @moduledoc """
  ## Examples

      mix test.prepare
  """
  def run(args) do
    Mix.Task.run "app.start", args
    OptionParser.parse(args)

    :ssl.start()
    :os.putenv("AWS_DYNAMO_DB_PREFIX","test.ex_model_dynamo_db.")
    :erlcloud.start()

    TestModels.prepare()
 
  end
end