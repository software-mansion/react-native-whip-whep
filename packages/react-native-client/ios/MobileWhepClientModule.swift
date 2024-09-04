import ExpoModulesCore

public class MobileWhepClientModule: Module {
    private var client: WhepClient?

  public func definition() -> ModuleDefinition {
    Name("MobileWhepClient")

    Constants([
      "PI": Double.pi
    ])

    // Defines event names that the module can send to JavaScript.
    Events("onChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      return "Hello world! 👋"
    }
      
      // Dodanie funkcji asynchronicznej do tworzenia obiektu WhepClient
      AsyncFunction("createClient") { (serverUrl: String, configurationOptions: [String: AnyObject]?) in
        guard let url = URL(string: serverUrl) else {
          throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let options = ConfigurationOptions(
          stunServerUrl: configurationOptions?["stunServerUrl"] as? String,
          audioEnabled: configurationOptions?["audioEnabled"] as? Bool ?? true,
          videoEnabled: configurationOptions?["videoEnabled"] as? Bool ?? true
        )

        self.client = WhepClient(serverUrl: url, configurationOptions: options)
      }

      // Dodanie funkcji asynchronicznej do połączenia się z serwerem
      AsyncFunction("connect") {
        guard let client = self.client else {
          throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Client not found"])
        }
        try await client.connect()
      }

      // Dodanie funkcji do rozłączenia się z serwerem
      Function("disconnect") {
        guard let client = self.client else {
          throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Client not found"])
        }
        client.disconnect()
      }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { (value: String) in
      // Send an event to JavaScript.
      self.sendEvent("onChange", [
        "value": value
      ])
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.
    View(MobileWhepClientView.self) {
      // Defines a setter for the `name` prop.
      Prop("name") { (view: MobileWhepClientView, prop: String) in
        print(prop)
      }
    }
  }
}
