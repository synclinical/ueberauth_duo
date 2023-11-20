defmodule Ueberauth.Strategy.Duo do
  use Ueberauth.Strategy,
    uid_field: :sub,
    default_scope: "openid email profile"

  alias Plug.Conn
  alias Ueberauth.Auth.{Info, Credentials, Extra}
  alias Ueberauth.Strategy.Duo.OAuth

  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    params = [scope: scopes] |> with_state_param(conn)
    opts   = options(conn) |> Keyword.put(:redirect_uri, callback_url(conn))

    redirect!(conn, OAuth.authorize_url!(params, opts))
  end

  @impl Ueberauth.Strategy
  def handle_callback!(%Conn{params: %{"code" => code}} = conn) do
    opts  = options(conn) |> Keyword.put(:redirect_uri, callback_url(conn))
    client = OAuth.get_token!([code: code], opts)
    token  = client.token

    case token do
      nil ->
        err = token.other_params["error"]
        desc = token.other_params["error_description"]
        set_errors!(conn, [error(err, desc)])

      _token ->
        fetch_user(conn, token)
    end
  rescue
    err in [Error] ->
      set_errors!(conn, [error("OAuth2", err.reason)])
  end

  @impl Ueberauth.Strategy
  def handle_callback!(%Conn{params: %{"error" => key, "error_description" => message}} = conn) do
    set_errors!(conn, [error(key, message)])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Duo response around during the callback.
  """
  @impl Ueberauth.Strategy
  def handle_cleanup!(conn) do
    conn
    |> put_private(:duo_user, nil)
    |> put_private(:duo_token, nil)
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  @impl Ueberauth.Strategy
  def info(conn) do
    user = conn.private.duo_user

    %Info{
      email: user["email"],
      first_name: user["given_name"],
      last_name: user["family_name"],
      name: user["name"],
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Duo callback.
  """
  @impl Ueberauth.Strategy
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.duo_token,
        user: conn.private.duo_user
      }
    }
  end

  @doc """
  Includes the credentials from the Duo response.
  """
  @impl Ueberauth.Strategy
  def credentials(conn) do
    token = conn.private.duo_token

    %Credentials{
      token: token.access_token,
      token_type: token.token_type,
      refresh_token: token.refresh_token,
      expires: token.expires_at != nil,
      expires_at: token.expires_at,
      scopes: token.other_params["scope"]
    }
  end

  @doc """
  Fetches the uid field from the Duo response. This defaults to the option `uid_field` which in-turn defaults to `sub`
  """
  @impl Ueberauth.Strategy
  def uid(conn) do
    conn
    |> option(:uid_field)
    |> to_string()
    |> fetch_uid(conn)
  end

  defp fetch_uid(field, conn) do
    conn.private.duo_user[field]
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :duo_token, token)
    opts = options(conn) |> Keyword.put(:token, token)

    with {:ok, user} <- Ueberauth.Strategy.Duo.OAuth.get_user_info(_headers = [], opts) do
      put_private(conn, :duo_user, user)
    else
      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", inspect(reason))])

      {:error, %{status_code: 401}} ->
        set_errors!(conn, [error("Duo token [401]", "unauthorized")])

      {:error, %{status_code: status, body: body}} when status in 400..599 ->
        set_errors!(conn, [error("Duo [#{status}]", inspect(body))])
    end
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options()
    |> Keyword.get(key, default)
  end

end
