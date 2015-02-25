Code.require_file "../../../test/test_helper.exs", __ENV__.file

defmodule Mix.Tasks.Test.Prepare do
  use Mix.Task

  @shortdoc "Prepares environment for testing. Remember to set MIX_ENV=test !!!"

  @moduledoc """
  ## Examples

      mix test.prepare
  """
  def run(args) do
    Mix.Task.run "app.start", args
    OptionParser.parse(args)

    :ssl.start()
    :erlcloud.start()

    TestModels.prepare()
 
  end
end