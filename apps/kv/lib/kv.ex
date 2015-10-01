defmodule KV do
  use Application

  def start(_typ, _args) do
    KV.Supervisor.start_link
  end
end
