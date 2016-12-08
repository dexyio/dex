defmodule Dex.Service.Plugins.MailTest do

  use ExUnit.Case, async: false
  use Dex.Test
  import Bamboo.Email
  alias Dex.Service.Plugins.Mail

  setup do
    :ok
  end

  test "mailgun" do
    #assert %Bamboo.Email{} = test_mail |> Mail.deliver_now
    #assert {_, "ok"} = send_mail 
    :ok
  end

  defp test_mail do
    new_email \
      to: "winfavor@gmail.com",
      from: "noreply@dexy.io",
      subject: "Confirm your subscription",
      html_body: """
        <h2>Please Confirm Subscription</h2>
        <p><a href="http://dexy.io:8082"><span>Yes, subscribe me to dexy.io</span></a></p>
        <div>
          <p>If you received this email by mistake, simply delete it. You won't be subscribed if you don't click the confirmation link above.</p>
        </div>
      """
  end

  defp send_mail do
    opts = %{
      "to" => "winfavor@gmail.com",
      "from" => "noreply@dexy.io",
      "subject" => "Confirm your subscription 2",
      "html" => """
        <h2>Please Confirm Subscription 2</h2>
        <p><a href="http://dexy.io:8082"><span>Yes, subscribe me to dexy.io</span></a></p>
        <div>
          <p>If you received this email by mistake, simply delete it. You won't be subscribed if you don't click the confirmation link above.</p>
        </div>
      """
    }
    Mail.send %{opts: opts}
  end

end
