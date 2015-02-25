Code.require_file "../../../test/test_helper.exs", __ENV__.file

defmodule Mix.Tasks.Test.Teardown do
  use Mix.Task

  @shortdoc "Teardown tables used for testing"

  @moduledoc """
  ## Examples

      mix ddbmodel.test.prepare
  """
  def run(args) do
    Mix.Task.run "app.start", args
    OptionParser.parse(args)

    :ssl.start()
    :erlcloud.start()

    TestModels.teardown
 
  end
end