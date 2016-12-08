defmodule Dex.Service.Plugins.Mail do

  use Dex.Common
  use Dex.Service.Helper
  use Bamboo.Mailer, otp_app: :dex
  require Logger
  import Bamboo.Email

  def send state = %{args: [], opts: opts} do do_send state, opts end

  defp do_send(state, opts) do
    case Enum.map(opts, &do_send &1) |> new_email |> deliver_now do
      %Bamboo.Email{} -> {state, "ok"}
      error -> Logger.warn inspect(error); {state, "error"}
    end
  end

  defp do_send({"from", val}) when is_bitstring(val), do: {:from, val}
  defp do_send({"to", val}) when is_list(val) or is_bitstring(val), do: {:to, val}
  defp do_send({"cc", val}) when is_list(val) or is_bitstring(val), do: {:cc, val}
  defp do_send({"bcc", val}) when is_list(val) or is_bitstring(val), do: {:bcc, val}
  defp do_send({"subject", val}) when is_list(val) or is_bitstring(val), do: {:subject, val}
  defp do_send({"text", val}) when is_list(val) or is_bitstring(val), do: {:text_body, val}
  defp do_send({"html", val}) when is_list(val) or is_bitstring(val), do: {:html_body, val}

end
