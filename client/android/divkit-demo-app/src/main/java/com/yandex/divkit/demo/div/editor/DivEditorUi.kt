package com.yandex.divkit.demo.div.editor

import android.graphics.Bitmap
import android.view.View
import android.view.View.*
import android.view.ViewGroup
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.yandex.divkit.demo.Container
import com.yandex.divkit.demo.div.Div2MetadataBottomSheet
import com.yandex.divkit.demo.div.editor.DivEditorScreenshot.takeScreenshot
import com.yandex.divkit.demo.div.editor.list.DivEditorAdapter
import com.yandex.divkit.demo.div.histogram.LoggingHistogramBridge

class DivEditorUi(
    private val activity: AppCompatActivity,
    private val metadataButton: FloatingActionButton,
    private val failedTextMessage: TextView,
    private val divContainer: ViewGroup,
    private val div2Recycler: RecyclerView,
    private val div2Adapter: DivEditorAdapter,
    private val metadataHost: Div2MetadataBottomSheet.MetadataHost,
    private val showRenderTime: Boolean,
) {

    var onDiv2ViewDrawnListener: ((bitmap: Bitmap) -> Unit)? = null
    var hasTemplates: Boolean = false

    private val debounceOnViewDrawObserver = DebounceOnViewDrawObserver {
        activity.takeScreenshot { screenshot: Bitmap ->
            onDiv2ViewDrawnListener?.invoke(screenshot)
        }
        updateRenderTime()
    }

    fun updateState(newState: DivEditorState) {
        when (newState) {
            is DivEditorState.InitialState -> {
                showInitialState()
            }
            is DivEditorState.LoadingState -> {
                showLoadingState()
            }
            is DivEditorState.DivReceivedState -> {
                showDivReceivedState(newState)
            }
            is DivEditorState.FailedState -> {
                showFailedState(newState)
            }
        }
    }

    private fun showInitialState() {
        hideAll()
    }

    private fun updateRenderTime() {
        if (showRenderTime) {
            metadataButton.visibility = VISIBLE
            metadataHost.renderingTimeMessages.clear()
            val histogramBridge = Container.histogramConfiguration.histogramBridge.get()
                as LoggingHistogramBridge
            metadataHost.renderingTimeMessages.add("Div render time: \n")
            histogramBridge.getLastSavedHistogram("$DEMO_ACTIVITY_COMPONENT_NAME.Div.Render.Total")?.let {
                metadataHost.renderingTimeMessages.add("• Div.Render.Total: $it ms")
            }
            histogramBridge.getLastSavedHistogram("$DEMO_ACTIVITY_COMPONENT_NAME.Div.Parsing.Data")?.let {
                metadataHost.renderingTimeMessages.add("• Div.Parsing.Data: $it ms")
            }
            if (hasTemplates) {
                histogramBridge.getLastSavedHistogram("$DEMO_ACTIVITY_COMPONENT_NAME.Div.Parsing.Templates")?.let {
                    metadataHost.renderingTimeMessages.add("• Div.Parsing.Templates: $it ms")
                }
            }
        } else {
            metadataHost.renderingTimeMessages.clear()
            metadataButton.visibility = GONE
            return
        }
    }

    private fun showLoadingState() {
        hideAll()
        failedTextMessage.visibility = VISIBLE
        metadataHost.renderingTimeMessages.clear()
        metadataButton.visibility = GONE
        failedTextMessage.text = "Loading..."
    }

    private fun showFailedState(failedState: DivEditorState.FailedState) {
        hideAll()
        failedTextMessage.visibility = VISIBLE
        failedTextMessage.text = failedState.message
        debounceOnViewDrawObserver.onDraw()
    }

    private fun showDivReceivedState(state: DivEditorState.DivReceivedState) {
        hideAll()
        div2Adapter.setList(state.divDataList)
        div2Recycler.viewTreeObserver.addOnDrawListener(debounceOnViewDrawObserver)

        // Make sure onDiv2ViewDrawnListener called, even if div2View not going to be drawn.
        debounceOnViewDrawObserver.onDraw()
    }

    private fun hideAll() {
        metadataButton.visibility = GONE
        failedTextMessage.visibility = GONE
        divContainer.viewTreeObserver.removeOnDrawListener(debounceOnViewDrawObserver)
    }
}
