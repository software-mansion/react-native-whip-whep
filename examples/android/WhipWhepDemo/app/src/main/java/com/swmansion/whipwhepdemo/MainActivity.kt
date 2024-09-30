package com.swmansion.whipwhepdemo

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
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
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.mobilewhep.client.VideoView
import com.swmansion.whipwhepdemo.ui.theme.WhipWhepDemoTheme

class MainActivity : ComponentActivity() {
  private val PERMISSIONS_REQUEST_CODE = 101
  private val REQUIRED_PERMISSIONS = arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)

  private val viewModel by viewModels<MainActivityViewModel>()

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
          PlayerView(modifier = Modifier.padding(innerPadding), viewModel = viewModel)
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
fun PlayerView(
  modifier: Modifier = Modifier,
  viewModel: MainActivityViewModel
) {
  var whepView: VideoView? =
    remember {
      null
    }

  var whepServerView: VideoView? =
    remember {
      null
    }

  var whipView: VideoView? =
    remember {
      null
    }

  DisposableEffect(Unit) {
    onDispose {
      viewModel.disconnect()
      whepView?.release()
      whepServerView?.release()
      whipView?.release()
    }
  }

  @Composable
  fun WhepBroadcasterTab() {
    val shouldShowPlayBtn by viewModel.shouldShowPlayBtn
    val isLoading by viewModel.isLoading
    Box {
      AndroidView(
        factory = { ctx ->
          VideoView(ctx).apply {
            player = viewModel.whepBroadcaster
          }
        },
        modifier =
          Modifier
            .fillMaxWidth()
            .height(200.dp)
      )

      if (shouldShowPlayBtn) {
        Button(onClick = { viewModel.onBroadcasterPlay() }, modifier = Modifier.align(Alignment.Center)) {
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
  fun WhepTab() {
    val shouldShowPlayBtn by viewModel.shouldShowPlayBtn
    val isLoading by viewModel.isLoading
    Box {
      AndroidView(
        factory = { ctx ->
          VideoView(ctx).apply {
            player = viewModel.whepClient
          }
        },
        modifier =
          Modifier
            .fillMaxWidth()
            .height(200.dp)
      )

      if (shouldShowPlayBtn) {
        Button(onClick = { viewModel.onPlay() }, modifier = Modifier.align(Alignment.Center)) {
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
  fun WhipTab() {
    Column(
      modifier =
        Modifier
          .fillMaxSize(),
      horizontalAlignment = Alignment.CenterHorizontally
    ) {
      val shouldShowStreamBtn by viewModel.shouldShowStreamBtn
      AndroidView(
        factory = { ctx ->
          VideoView(ctx).apply {
            player = viewModel.whipClient
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
          Button(onClick = { viewModel.onStream() }) {
            Text("Stream")
          }
        }
      }
    }
  }

  @Composable
  fun TabView() {
    val tabTitles = listOf("WHEP (broadcaster)", "WHEP", "WHIP")
    val selectedTabIndex by viewModel.selectedTabIndex

    Column(modifier = Modifier.fillMaxSize()) {
      TabRow(selectedTabIndex = selectedTabIndex.ordinal) {
        tabTitles.forEachIndexed { index, title ->
          Tab(
            selected = selectedTabIndex.ordinal == index,
            onClick = { viewModel.switchTab(Tabs.entries[index]) },
            text = { Text(title) }
          )
        }
      }

      when (selectedTabIndex) {
        Tabs.WHEP_BROADCASTER_TAB -> WhepBroadcasterTab()
        Tabs.WHEP_TAB -> WhepTab()
        Tabs.WHIP_TAB -> WhipTab()
      }
    }
  }
  Box(
    modifier =
      Modifier
        .fillMaxSize()
        .padding(top = 50.dp)
  ) {
    TabView()
  }
}
