defmodule Dex.Service.Plugins.MailTest do

  use ExUnit.Case, async: false
  use Dex.Test

  setup do
    :ok
  end

  test "mail" do
    assert {_, "ok"} = send_mail 
  end

  test "mail plugin'" do
    ~S"""
    @dexyml
    | mail.send to: "winfavor@gmail.com"
                from: {"Dexy.IO", "noreply@dexy.io"}
                subject: "Confirm your subscription"
                html: "<h1> Hi </hi>"
    """ |> assert!(nil)
  end

  def send_mail do
    opts = %{
      "to" => "winfavor@gmail.com",
      "from" => "noreply@dexy.io",
      "subject" => "Confirm your subscription",
      "html" => """
        <h2>Please Confirm Subscription</h2>
        <p><a href="http://dexy.io:8082"><span>Yes, subscribe me to dexy.io</span></a></p>
        <div>
          <p>If you received this email by mistake, simply delete it. You won't be subscribed if you don't click the confirmation link above.</p>
        </div>
      """
    }
    DexyPluginMail.send %{args: [], opts: opts}
  end

end
