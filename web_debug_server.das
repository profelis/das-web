options indenting = 2
module web_debug_server shared

require fio

require web_server public


def run_debug_server(var server: WebServer?): bool
  if !start_server(server)
    return false

  while true
    server->tick()
    sleep(0u)

  server->stop()
  unsafe
    delete server
  return true
