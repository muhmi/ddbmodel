require Record

defmodule LocalDynamoConfig do
  Record.defrecord :aws_config, Record.extract(:aws_config, from_lib: "erlcloud/include/erlcloud_aws.hrl")

  def get do
    aws_config(ddb_scheme: 'http://', ddb_host: 'localhost', ddb_port: 8000, 
      access_key_id: 'ddbmodeltest',
      secret_access_key: 'ddbmodeltest'
      )
  end
end
