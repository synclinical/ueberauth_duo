defmodule Ueberauth.Strategy.Duo.OAuth do
  use OAuth2.Strategy

  alias Ueberauth
  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode

  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__)
    json_library = Ueberauth.json_library()

    defaults()
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
    |> validate_config_option!(:client_id)
    |> validate_config_option!(:client_secret)
    |> validate_config_option!(:site)
    |> Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ []) do
    opts
    |> client
    |> Client.get_token!(params)
  end

  def get_user_info(headers \\ [], opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__)
    userinfo_url = Keyword.get(opts, :userinfo_url) || Keyword.get(config, :userinfo_url, "/userinfo")
    client(opts)
    |> Client.get(userinfo_url, headers, opts)
    |> case do
      {:ok, %{status_code: 200, body: user}} -> {:ok, user}
      {:ok, result} -> {:error, result}
      err -> err
    end
  end

  # oauth2 Strategy Callbacks

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("Accept", "application/json")
    |> AuthCode.get_token(params, headers)
  end

  defp defaults() do
    [
      strategy: __MODULE__,
      authorize_url: "/authorize",
      token_url: "/token",
      request_opts: [ssl_options: [versions: [:"tlsv1.2"]]]
    ]
  end

  defp validate_config_option!(config, key) when is_list(config) do
    case Keyword.take(config, [key]) do
      [] ->
        raise "[Ueberauth.Strategy.Duo.OAuth] missing required key: #{inspect(key)} "

      [{_, ""}] ->
        raise "[Ueberauth.Strategy.Duo.OAuth] #{inspect(key)} is an empty string"

      [{:site, "http" <> _}] ->
        config

      [{:site, val}] ->
        raise "[Ueberauth.Strategy.Duo.OAuth] invalid :site - #{inspect(val)}"

      [{_, val}] when is_binary(val) ->
        config

      _ ->
        raise "[Ueberauth.Strategy.Duo.OAuth] #{inspect(key)} must be a string"
    end
  end

  defp validate_config_option!(_, _) do
    raise "[Ueberauth.Strategy.Duo.OAuth] strategy options must be a keyword list"
  end
end
