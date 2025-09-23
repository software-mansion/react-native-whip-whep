import ExpoModulesCore
import MobileWhipWhepClient

public class ReactNativeMobileWhipClientViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ReactNativeMobileWhipClientViewModule")
    
    View(ReactNativeMobileWhipClientView.self) {
      Prop("playerType") { (view: ReactNativeMobileWhipClientView, playerType: String) in
        view.playerType = playerType
      }
    }
  }
}
