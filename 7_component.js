Vue.component('my-component', {
  data: function () {
    return {
      "status": "no-status",
      "serverTime": "-1"
    }
  },
  mounted() {
    // init code
    jrpc.on("status", data => {
      console.log("status message ", data)
      this.status = data
    })
    jrpc.on("serverTime", data => {
      console.log("serverTime message ", data)
      this.serverTime = `${data}`
    })

    jrpc.notification("whatsup")
    jrpc.call('reverse', ["foobar"]).then(function (data) { console.log("revers of foobar", data) })
  },
  template: `
    <div>
      <p style="background-color: #e44">Status: {{ status }}</p>
      <p> Server time: {{ serverTime }}</p>
    </div>
  `
})