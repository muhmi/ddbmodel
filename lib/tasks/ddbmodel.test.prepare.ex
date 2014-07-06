Code.require_file "../../../test/test_helper.exs", __ENV__.file
Code.require_file "../../../test/local_dynamo_config.exs", __ENV__.file

defmodule Mix.Tasks.DDBModel.Test.Prepare do
  use Mix.Task
  import Mix.Generator
  import Mix.Utils, only: [camelize: 1]
  require LocalDynamoConfig

  @shortdoc "Prepares environment for testing"

  @moduledoc """
  ## Examples

      mix ddbmodel.test.prepare
  """
  def run(args) do
    Mix.Task.run "app.start", args
    {_, args, _} = OptionParser.parse(args)

    :ssl.start()
    :os.putenv("AWS_DYNAMO_DB_PREFIX","test.ex_model_dynamo_db.")
    :erlang.put(:aws_config, LocalDynamoConfig.get())
    :erlcloud.start()

    TestModels.prepare()
 
  end
end