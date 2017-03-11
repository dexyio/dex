defmodule Dex.Code do

  defmacro ok, do: 200
  defmacro created, do: 201
  defmacro accepted, do: 202
  defmacro no_content, do: 204

  defmacro bad_request, do: 400
  defmacro unauthorized, do: 401
  defmacro payment_required, do: 402
  defmacro forbidden, do: 403
  defmacro not_found, do: 404
  defmacro method_not_allowed, do: 405
  defmacro request_timeout, do: 408
  defmacro conflict, do: 409

  defmacro internal_server_error, do: 500
  defmacro not_implemented, do: 501
  defmacro service_unavilable, do: 503

  def code("ok"), do: ok()
  def code("created"), do: created()
  def code("accepted"), do: accepted()
  def code("no_content"), do: no_content()

  def code("bad_request"), do: bad_request()
  def code("unauthorized"), do: unauthorized()
  def code("payment_required"), do: payment_required()
  def code("forbidden"), do: forbidden()
  def code("not_found"), do: not_found()
  def code("method_not_allowed"), do: method_not_allowed()
  def code("request_timeout"), do: request_timeout()
  def code("conflict"), do: conflict()

  def code("internal_server_error"), do: bad_request()
  def code("not_implemented"), do: bad_request()
  def code("service_unavilable"), do: bad_request()

  def code(_), do: ok()

end
