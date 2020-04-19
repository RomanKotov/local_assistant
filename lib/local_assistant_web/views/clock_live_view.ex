defmodule LocalAssistantWeb.ClockLiveView do
  use LocalAssistantWeb, :view

  def format(n) when is_integer(n) and n < 10, do: "0#{n}"
  def format(n), do: "#{n}"
end
