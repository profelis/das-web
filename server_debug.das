options indenting = 2
options strict_smart_pointers
module server_debug shared

require fio

require server public


def run_debug_server(var server: WebServer?; fileName:string): bool
  if !start_server(server)
    return false
  let main_time = stat(fileName).mtime

  while !server.done
    server->tick()
    let new_time = stat(fileName).mtime
    if new_time != main_time
      print("restarting via source change {new_time}\n")
      server->restart()
      break
    sleep(10u)
  unsafe
    delete server
  return true
