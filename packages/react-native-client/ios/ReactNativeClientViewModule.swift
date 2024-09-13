import ExpoModulesCore

public class ReactNativeClientViewModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ReactNativeClientViewModule")
        
        View(ReactNativeClientView.self) {
        }
    }
}
