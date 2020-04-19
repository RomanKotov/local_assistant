defmodule LocalAssistantWeb.PlayerLive do
  use LocalAssistantWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, action: Map.get(session, "action", "index"))}
  end

  @impl true
  def render(%{action: action} = assigns) do
    Phoenix.View.render(LocalAssistantWeb.PlayerLiveView, "#{action}.html", assigns)
  end
end
