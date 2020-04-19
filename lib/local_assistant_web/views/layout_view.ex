defmodule LocalAssistantWeb.LayoutView do
  use LocalAssistantWeb, :view

  def is_main_page(%{view: LocalAssistantWeb.PageLive}), do: true
  def is_main_page(_), do: false
end
