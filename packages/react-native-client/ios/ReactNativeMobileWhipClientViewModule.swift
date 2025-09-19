import ExpoModulesCore
import MobileWhipWhepClient

public class ReactNativeMobileWhipClientViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ReactNativeMobileWhipClientViewModule")
    
    View(ReactNativeMobileWhipClientView.self) {
      Prop("playerType") { (view: ReactNativeMobileWhipClientView, playerType: String) in
        view.playerType = playerType
      }
      Prop("pipEnabled") { (view: ReactNativeMobileWhipClientView, pipEnabled: Bool) in
        view.pipEnabled = pipEnabled
      }
      Prop("autoStartPip") { (view: ReactNativeMobileWhipClientView, startAutomatically: Bool) in
        view.pipController?.startAutomatically = startAutomatically
      }
      Prop("autoStopPip") { (view: ReactNativeMobileWhipClientView, stopAutomatically: Bool) in
        view.pipController?.stopAutomatically = stopAutomatically
      }
      Prop("pipSize"){ (view: ReactNativeMobileWhipClientView, size: CGSize) in
        view.pipController?.preferredSize = size
      }
      
      AsyncFunction("startPip") { (view: ReactNativeMobileWhipClientView) in
        view.pipController?.startPictureInPicture()
      }
      
      AsyncFunction("stopPip") { (view: ReactNativeMobileWhipClientView) in
        view.pipController?.stopPictureInPicture()
      }
      
      AsyncFunction("togglePip") { (view: ReactNativeMobileWhipClientView) in
        view.pipController?.togglePictureInPicture()
      }
    }
  }
}
