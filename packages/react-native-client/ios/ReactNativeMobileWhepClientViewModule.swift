import ExpoModulesCore

public class ReactNativeMobileWhepClientViewModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ReactNativeMobileWhepClientViewModule")
        
        View(ReactNativeMobileWhepClientView.self) {
            Prop("playerType") { (view: ReactNativeMobileWhepClientView, playerType: String) in
                view.playerType = playerType
            }
        }
    }
}
