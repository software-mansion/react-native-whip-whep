package com.swmansion.androidexample

import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
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
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.swmansion.androidexample.ui.theme.AndroidExampleTheme
import kotlinx.coroutines.launch
import org.webrtc.RendererCommon
import android.Manifest
import android.util.Log
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text

class MainActivity : ComponentActivity() {
  private val PERMISSIONS_REQUEST_CODE = 101
  private val REQUIRED_PERMISSIONS = arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    if (!hasPermissions(this, REQUIRED_PERMISSIONS)) {
      ActivityCompat.requestPermissions(this, REQUIRED_PERMISSIONS, PERMISSIONS_REQUEST_CODE)
    } else {
      setupContent()
    }
  }

  private fun setupContent() {
    enableEdgeToEdge()
    setContent {
      AndroidExampleTheme {
        Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
          PlayerView(modifier = Modifier.padding(innerPadding))
        }
      }
    }
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
    if (requestCode == PERMISSIONS_REQUEST_CODE) {
      var allPermissionsGranted = true
      for (result in grantResults) {
        allPermissionsGranted = allPermissionsGranted and (result == PackageManager.PERMISSION_GRANTED)
      }

      if (allPermissionsGranted) {
        setupContent()
      } else {
        Toast.makeText(this, "Permissions not granted.", Toast.LENGTH_SHORT).show()
        finish()
      }
    }

    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
  }

  private fun hasPermissions(context: Context, permissions: Array<String>): Boolean {
    for (permission in permissions) {
      if (ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
        return false
      }
    }
    return true
  }
}

@Composable
fun PlayerView(modifier: Modifier = Modifier) {
  val context = LocalContext.current

  var isLoading by remember { mutableStateOf(false) }
  var shouldShowPlayBtn by remember {
    mutableStateOf(true)
  }
  var shouldShowStreamBtn by remember {
    mutableStateOf(true)
  }

  val whepPlayer = remember {
    WHEPPlayer(
      context,
      ConnectionOptions(serverUrl = "http://192.168.83.171:8829", whepEndpoint = "/whep", authToken = "example")
    )
  }

  val whipPlayer = remember {
    WHIPPlayer(
      context,
      ConnectionOptions(serverUrl = "http://192.168.83.171:8829", whepEndpoint = "/whip", authToken = "example")
    )
  }
  Log.d("PRINT", whepPlayer.toString())
  Log.d("PRINT", whipPlayer.toString())


  var whipView: WHIPPlayerView? = remember {
    null
  }

  var view: WHEPPlayerView? = remember {
    null
  }


  DisposableEffect(Unit) {
    onDispose {
      whepPlayer.release()
      whipPlayer.release()
      view?.release()
      whipView?.release()
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

  fun onStreamBtnClick() {
    shouldShowStreamBtn = false
    coroutineScope.launch {
      whipPlayer.connect()
    }
  }

  Column(modifier = Modifier.fillMaxSize()) {

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
        modifier = modifier
          .fillMaxWidth()
          .height(200.dp)
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
          modifier = Modifier
            .width(64.dp)
            .align(Alignment.Center),
          color = MaterialTheme.colorScheme.secondary,
          trackColor = MaterialTheme.colorScheme.surfaceVariant,
        )
      }
    }

    AndroidView(
      factory = { ctx ->
        WHIPPlayerView(ctx).apply {
          player = whipPlayer
          whipView = this
        }
      },
      modifier = modifier
        .fillMaxWidth()
        .height(200.dp)
    )
    if (shouldShowStreamBtn) {
      Button(onClick = { onStreamBtnClick() }) {
        Text("Stream")
      }
    }
  }
}
