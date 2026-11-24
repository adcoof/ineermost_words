package app.airoleplay.ai_roleplay_chat

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * 无障碍服务：读屏文字 + 按文字点击。
 * 只在用户于系统设置中主动开启后生效；Shizuku 不可用时的兜底操作通道。
 */
class XinyuAccessibilityService : AccessibilityService() {
    companion object {
        @Volatile
        var instance: XinyuAccessibilityService? = null
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    /** 遍历当前窗口，收集可见文字（去重、最多 200 条）。 */
    fun screenText(): String {
        val root = rootInActiveWindow ?: return ""
        val out = LinkedHashSet<String>()
        collectText(root, out, 0)
        return out.take(200).joinToString("\n")
    }

    /** 按文字/描述精确或包含匹配，找到第一个可点击节点并点击。返回是否成功。 */
    fun clickText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val target = findNode(root, text.trim(), 0) ?: return false
        var node: AccessibilityNodeInfo? = target
        while (node != null) {
            if (node.isClickable) {
                return node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            }
            node = node.parent
        }
        return false
    }

    private fun collectText(node: AccessibilityNodeInfo, out: MutableSet<String>, depth: Int) {
        if (depth > 40) return
        val text = node.text?.toString()?.trim().orEmpty()
        val desc = node.contentDescription?.toString()?.trim().orEmpty()
        if (text.isNotEmpty()) out.add(text)
        if (desc.isNotEmpty()) out.add(desc)
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            collectText(child, out, depth + 1)
        }
    }

    private fun findNode(node: AccessibilityNodeInfo, text: String, depth: Int): AccessibilityNodeInfo? {
        if (depth > 40) return null
        val label = node.text?.toString()?.trim().orEmpty()
        val desc = node.contentDescription?.toString()?.trim().orEmpty()
        if (label == text || desc == text) return node
        if (label.contains(text) || desc.contains(text)) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findNode(child, text, depth + 1)
            if (found != null) return found
        }
        return null
    }
}
