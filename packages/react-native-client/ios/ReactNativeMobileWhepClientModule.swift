import ExpoModulesCore
import MobileWhipWhepClient
import WebRTC

public class ReactNativeMobileWhepClientModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ReactNativeMobileWhepClient")

        Events(EmitableEvent.allEvents)   
    }
}
