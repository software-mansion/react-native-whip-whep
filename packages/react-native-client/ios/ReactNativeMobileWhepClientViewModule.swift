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
      Prop("pipEnabled") { (view: ReactNativeMobileWhepClientView, pipEnabled: Bool) in
        view.pipEnabled = pipEnabled
      }
      Prop("autoStartPip") { (view: ReactNativeMobileWhepClientView, startAutomatically: Bool) in
        view.pipController?.startAutomatically = startAutomatically
      }
      Prop("autoStopPip") { (view: ReactNativeMobileWhepClientView, stopAutomatically: Bool) in
        view.pipController?.stopAutomatically = stopAutomatically
      }
      Prop("pipSize"){ (view: ReactNativeMobileWhepClientView, size: CGSize) in
        view.pipController?.preferredSize = size
      }
      
      AsyncFunction("startPip") { (view: ReactNativeMobileWhepClientView) in
        view.pipController?.startPictureInPicture()
      }
      
      AsyncFunction("stopPip") { (view: ReactNativeMobileWhepClientView) in
        view.pipController?.stopPictureInPicture()
      }
      
      AsyncFunction("togglePip") { (view: ReactNativeMobileWhepClientView) in
        view.pipController?.togglePictureInPicture()
      }
    }
  }
}
