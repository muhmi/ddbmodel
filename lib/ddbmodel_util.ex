defmodule DDBModel.Util do   
  def unix_timestamp do
    utc = :calendar.now_to_universal_time(:erlang.now())
    greg = :calendar.datetime_to_gregorian_seconds(utc) 
    greg_1970 = :calendar.datetime_to_gregorian_seconds( {{1970,1,1},{0,0,0}} )

    greg - greg_1970
  end
end
