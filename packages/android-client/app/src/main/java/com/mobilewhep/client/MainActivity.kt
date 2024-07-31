package com.mobilewhep.client

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.swmansion.whepclient.ConnectionOptions
import com.swmansion.whepclient.WHEPPlayer
import com.swmansion.whepclient.WHEPPlayerView
import com.swmansion.whepclient.ui.theme.MobileWhepClientTheme
import kotlinx.coroutines.launch
import org.webrtc.RendererCommon

class MainActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    enableEdgeToEdge()
    setContent {
      MobileWhepClientTheme {
        Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
          PlayerView(modifier = Modifier.padding(innerPadding))
        }
      }
    }
  }
}

@Composable
fun PlayerView(modifier: Modifier = Modifier) {
  val context = LocalContext.current

  var isLoading by remember { mutableStateOf(false) }
  var shouldShowPlayBtn by remember {
    mutableStateOf(true)
  }

  val whepPlayer =
    remember {
      WHEPPlayer(
        context,
        ConnectionOptions(serverUrl = "http://192.168.0.31:8829/", whepEndpoint = "/whep")
      )
    }

  var view: WHEPPlayerView? =
    remember {
      null
    }

  DisposableEffect(Unit) {
    onDispose {
      whepPlayer.release()
      view?.release()
    }
  }

  val coroutineScope = rememberCoroutineScope()

  fun onPlayBtnClick() {
    shouldShowPlayBtn = false
    isLoading = true
    whepPlayer.onTrackAdded = { isLoading = false }
    coroutineScope.launch {
      whepPlayer.connect()
    }
  }

  Box {
    AndroidView(
      factory = { ctx ->
        WHEPPlayerView(ctx).apply {
          player = whepPlayer
          this.setScalingType(RendererCommon.ScalingType.SCALE_ASPECT_FIT)
          this.setEnableHardwareScaler(true)
          view = this
        }
      },
      modifier =
        modifier
          .fillMaxWidth()
          .height(400.dp)
          .align(Alignment.Center)
    )
    if (shouldShowPlayBtn) {
      Button(onClick = { onPlayBtnClick() }, modifier = Modifier.align(Alignment.Center)) {
        Image(
          painter = painterResource(id = android.R.drawable.ic_media_play),
          contentDescription = "play"
        )
      }
    }
    if (isLoading) {
      CircularProgressIndicator(
        modifier =
          Modifier
            .width(64.dp)
            .align(Alignment.Center),
        color = MaterialTheme.colorScheme.secondary,
        trackColor = MaterialTheme.colorScheme.surfaceVariant
      )
    }
  }
}
