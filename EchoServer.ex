defmodule EchoServer do

  require Logger

  def accept(port) do

    {:ok, socket} = :gen_tcp.listen(port,

      [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info "Accepting connections on port #{port}"

    loop_acceptor(socket)

  end

  defp loop_acceptor(socket) do

    {:ok, client} = :gen_tcp.accept(socket)
    Task.start_link(fn ->

        serve(client)
    end)

    loop_acceptor(socket)
  end

  defp serve(socket) do

    socket |> read_line() |> read_file() |> write_line(socket)

    :ok = :gen_tcp.close(socket)

  end

  defp read_line(socket) do

    {:ok, data} = :gen_tcp.recv(socket, 0)
    if not String.contains?(data,"/favicon.ico") do
        if String.contains?(data,".html") do
            String.downcase(String.trim((String.replace(String.replace(data,"GET /",""),"HTTP/1.1",""))))
          else
            if String.equivalent?(String.downcase(String.trim((String.replace(String.replace(data,"GET ",""),"HTTP/1.1","")))),"/") do
              "/Users/tonnyhuey/Elixir/test.html"
            else
              relative = String.downcase(String.trim((String.replace(String.replace(data,"GET /",""),"HTTP/1.1",""))))
              Logger.info "RELATIVE #{relative}"
              Path.join("/Users/tonnyhuey/Elixir/test.html", relative)
            end
          end
        end
  end

  defp write_line(line, socket) do

    :gen_tcp.send(socket, line)

  end

  defp read_file(file_path) do
      if not is_nil(file_path) do
        Logger.info (""<>file_path<>"")
        try do
          File.read!(file_path)
        rescue
          _ in FileError ->
            "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n"<>File.read!("404File.html")
        end
      end
    end

  def main(_args \\ []) do

    accept(9999)
  end
end