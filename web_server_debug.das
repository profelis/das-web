options indenting = 2
options strict_smart_pointers
module web_server_debug shared

require fio

require web_server public

[unused_argument(fn)] // for compatibility with server_debug
def run_debug_server(var server: WebServer?; fn: string): bool
  return run_debug_server(server)

def run_debug_server(var server: WebServer?): bool
  if !start_server(server)
    return false

  while true
    server->tick()
    sleep(10u)

  server->stop()
  unsafe
    delete server
  return true
