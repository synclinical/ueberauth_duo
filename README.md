# ueberauth_duo

> Cisco Duo OAuth2 strategy for Überauth.

## Installation

1.  Set up your Duo OICD application by following these [instructions](https://duo.com/docs/sso-oidc-generic).

2.  Add `:ueberauth_duo` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:ueberauth_duo, "~> 1.0"}
      ]
    end
    ```

3.  Ensure `ueberauth_duo` is started before your application:

    ```elixir
    def application do
      [
        extra_applications: [:ueberauth_duo]
      ]
    end
    ```

4.  Add Duo to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        duo: {Ueberauth.Strategy.Duo, []}
      ],
    ```

5.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Duo.OAuth,
      site: System.get_env("DUO_SITE"),
      client_id: System.get_env("DUO_CLIENT_ID"),
      client_secret: System.get_env("DUO_CLIENT_SECRET")
    ```

6.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```
7.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

8. You controller needs to implement callbacks to deal with Ueberauth.Auth and Ueberauth.Failure responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Thanks!
This library is basically a copy and paste of the [Okta](https://github.com/appcues/ueberauth_okta) and [Microsoft](https://github.com/swelham/ueberauth_microsoft) Ueberauth strategies, and would not be possible without them. Thank you to the good people at [Appcues](https://www.appcues.com/) and to [Stuart Welham](https://github.com/swelham) for all your hard work.

## Learn about OAuth2
[OAuth2 explained with cute shapes](https://engineering.backmarket.com/oauth2-explained-with-cute-shapes-7eae51f20d38)

## Copyright and License

Copyright (c) 2023 Peter Lacey

This library is released under the MIT License. See the [LICENSE.md](./LICENSE.md) file
for further details.
