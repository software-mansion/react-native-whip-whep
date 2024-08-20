package com.swmansion.whipwhepdemo

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
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
import com.mobilewhep.client.ConfigurationOptions
import com.mobilewhep.client.WhepClient
import com.mobilewhep.client.WhipClient
import com.swmansion.whipwhepdemo.ui.theme.WhipWhepDemoTheme
import kotlinx.coroutines.launch
import org.webrtc.Camera1Enumerator
import org.webrtc.Camera2Enumerator
import org.webrtc.CameraEnumerator
import org.webrtc.RendererCommon

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
      WhipWhepDemoTheme {
        Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
          PlayerView(modifier = Modifier.padding(innerPadding))
        }
      }
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<String>,
    grantResults: IntArray
  ) {
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

  private fun hasPermissions(
    context: Context,
    permissions: Array<String>
  ): Boolean {
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
  val cameraEnumerator: CameraEnumerator =
    if (Camera2Enumerator.isSupported(context)) {
      Camera2Enumerator(context)
    } else {
      Camera1Enumerator(false)
    }

  val deviceName =
    cameraEnumerator.deviceNames.find {
      true
    }

  var isLoading by remember { mutableStateOf(false) }
  var shouldShowPlayBtn by remember {
    mutableStateOf(true)
  }
  var shouldShowStreamBtn by remember {
    mutableStateOf(true)
  }

  val whepClient =
    remember {
      WhepClient(
        appContext = context,
        serverUrl = context.getString(R.string.WHEP_SERVER_URL),
        configurationOptions = ConfigurationOptions(authToken = "example")
      )
    }

  val whipClient =
    remember {
      WhipClient(
        appContext = context,
        serverUrl =
          context.getString(
            R.string.WHIP_SERVER_URL
          ),
        configurationOptions = ConfigurationOptions(authToken = "example"),
        videoDevice = deviceName
      )
    }

  var whipView: ClientView? =
    remember {
      null
    }

  var view: ClientView? =
    remember {
      null
    }

  DisposableEffect(Unit) {
    onDispose {
      whepClient.disconnect()
      whipClient.disconnect()
      view?.release()
      whipView?.release()
    }
  }

  val coroutineScope = rememberCoroutineScope()

  fun onPlayBtnClick() {
    shouldShowPlayBtn = false
    isLoading = true
    whepClient.onTrackAdded = { isLoading = false }
    coroutineScope.launch {
      whepClient.connect()
    }
  }

  fun onStreamBtnClick() {
    shouldShowStreamBtn = false
    coroutineScope.launch {
      whipClient.connect()
    }
  }

  @Composable
  fun WHEPTab(
    whepPlayer: WhepClient,
    onPlayBtnClick: () -> Unit,
    shouldShowPlayBtn: Boolean,
    isLoading: Boolean
  ) {
    Box {
      AndroidView(
        factory = { ctx ->
          ClientView(ctx).apply {
            player = whepPlayer
            this.setScalingType(RendererCommon.ScalingType.SCALE_ASPECT_FIT)
            this.setEnableHardwareScaler(true)
          }
        },
        modifier =
          Modifier
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

  @Composable
  fun WHIPTab(
    whipPlayer: WhipClient,
    onStreamBtnClick: () -> Unit,
    shouldShowStreamBtn: Boolean
  ) {
    Column(
      modifier =
        Modifier
          .fillMaxSize(),
      horizontalAlignment = Alignment.CenterHorizontally
    ) {
      AndroidView(
        factory = { ctx ->
          ClientView(ctx).apply {
            player = whipPlayer
          }
        },
        modifier =
          Modifier
            .fillMaxWidth()
            .height(200.dp)
      )

      if (shouldShowStreamBtn) {
        Box(
          modifier =
            Modifier
              .padding(16.dp)
        ) {
          Button(onClick = { onStreamBtnClick() }) {
            Text("Stream")
          }
        }
      }
    }
  }

  @Composable
  fun TabView(
    whepPlayer: WhepClient,
    whipPlayer: WhipClient,
    onPlayBtnClick: () -> Unit,
    onStreamBtnClick: () -> Unit,
    shouldShowPlayBtn: Boolean,
    isLoading: Boolean,
    shouldShowStreamBtn: Boolean
  ) {
    val tabTitles = listOf("WHEP", "WHIP")
    var selectedTabIndex by remember { mutableStateOf(0) }

    Column(modifier = Modifier.fillMaxSize()) {
      TabRow(selectedTabIndex = selectedTabIndex) {
        tabTitles.forEachIndexed { index, title ->
          Tab(
            selected = selectedTabIndex == index,
            onClick = { selectedTabIndex = index },
            text = { Text(title) }
          )
        }
      }

      when (selectedTabIndex) {
        0 ->
          WHEPTab(
            whepPlayer = whepPlayer,
            onPlayBtnClick = onPlayBtnClick,
            shouldShowPlayBtn = shouldShowPlayBtn,
            isLoading = isLoading
          )
        1 ->
          WHIPTab(
            whipPlayer = whipPlayer,
            onStreamBtnClick = onStreamBtnClick,
            shouldShowStreamBtn = shouldShowStreamBtn
          )
      }
    }
  }
  Box(
    modifier =
      Modifier
        .fillMaxSize()
        .padding(top = 50.dp)
  ) {
    TabView(
      whepPlayer = whepClient,
      whipPlayer = whipClient,
      onPlayBtnClick = ::onPlayBtnClick,
      onStreamBtnClick = ::onStreamBtnClick,
      shouldShowPlayBtn = shouldShowPlayBtn,
      isLoading = isLoading,
      shouldShowStreamBtn = shouldShowStreamBtn
    )
  }
}
