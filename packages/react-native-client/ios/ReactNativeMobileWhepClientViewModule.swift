import ExpoModulesCore
import MobileWhipWhepClient

public class ReactNativeMobileWhepClientViewModule: Module {
    public func definition() -> ModuleDefinition {
        Name("ReactNativeMobileWhepClientViewModule")
        
        View(ReactNativeMobileWhepClientView.self) {
            Prop("playerType") { (view: ReactNativeMobileWhepClientView, playerType: String) in
                view.playerType = playerType
            }
            Prop("orientation") { (view: ReactNativeMobileWhepClientView, orientation: String) in
                view.orientation = Orientation(rawValue: orientation) ?? .portrait
            }
        }
    }
}
