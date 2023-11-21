defmodule XtbClient.RateLimitTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias XtbClient.RateLimit

  test "creates limit from positive integer interval" do
    sut = RateLimit.new(200)
    assert %{limit_interval: 200, time_stamp: 0} = sut

    assert_raise FunctionClauseError, fn ->
      RateLimit.new(-1)
    end
  end

  test "checks rate" do
    sut =
      RateLimit.new(200)
      |> Map.put(:time_stamp, DateTime.to_unix(DateTime.utc_now(), :millisecond))

    Process.sleep(250)

    current_stamp = DateTime.to_unix(DateTime.utc_now(), :millisecond)
    sut = RateLimit.check_rate(sut)

    assert %{limit_interval: 200, time_stamp: time_stamp} = sut
    assert time_stamp >= current_stamp
    assert time_stamp - current_stamp <= 50
  end

  test "checks rate and sleeps" do
    sut =
      RateLimit.new(200)
      |> Map.put(:time_stamp, DateTime.to_unix(DateTime.utc_now(), :millisecond))

    current_stamp = DateTime.to_unix(DateTime.utc_now(), :millisecond)
    sut = RateLimit.check_rate(sut)
    finish_stamp = DateTime.to_unix(DateTime.utc_now(), :millisecond)

    assert %{limit_interval: 200, time_stamp: time_stamp} = sut
    assert time_stamp >= current_stamp
    assert finish_stamp - current_stamp <= 200
  end
end
