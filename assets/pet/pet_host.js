// Live2D WebView 宿主：由 Dart 通过 evaluateJavascript 驱动，
// 通过 window.flutter_inappwebview.callHandler('petBridge', json) 回报事件。
//
// petHost API：
//   loadModel(entryUrl)              加载 model3.json（file:// 绝对路径）
//   setExpression(id)                切表情；空串复位
//   startMotion(group,index,priority) 播动作
//   setLipSync(v)                    口型 0..1（250ms 无新指令自动闭嘴）
//   setPointer(x,y)                  指针跟随（0..1 归一化）
/* global PIXI */
'use strict';

const petHost = (() => {
  let app = null;
  let model = null;
  let lipTimer = 0;

  function emit(event, extra) {
    const payload = Object.assign({ event: event }, extra || {});
    const json = JSON.stringify(payload);
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('petBridge', json);
    } else {
      console.log('[petBridge]', json);
    }
  }

  function ensureApp() {
    if (app) return app;
    // Pixi 6 的 view 必须是 canvas；让它自建 canvas 再挂到 #stage。
    app = new PIXI.Application({
      backgroundAlpha: 0,
      autoDensity: true,
      resizeTo: window,
    });
    document.getElementById('stage').appendChild(app.view);
    return app;
  }

  function fitModel() {
    if (!model || !app) return;
    const scale = Math.min(
      app.screen.width / model.internalModel.width,
      app.screen.height / model.internalModel.height
    ) * 1.05;
    model.scale.set(scale);
    model.anchor.set(0.5, 0.5);
    model.position.set(app.screen.width / 2, app.screen.height * 0.62);
  }

  async function loadModel(entryUrl) {
    try {
      ensureApp();
      if (model) {
        app.stage.removeChild(model);
        try { model.destroy(); } catch (e) { /* ignore */ }
        model = null;
      }
      model = await PIXI.live2d.Live2DModel.from(entryUrl, { autoInteract: false });
      fitModel();
      app.stage.addChild(model);

      model.on('pointerdown', (e) => {
        const bounds = model.getBounds();
        const relX = (e.global.x - bounds.x) / Math.max(1, bounds.width);
        const relY = (e.global.y - bounds.y) / Math.max(1, bounds.height);
        emit('tap', { x: relX, y: relY });
      });
      if (!fitModel.bound) {
        window.addEventListener('resize', fitModel);
        fitModel.bound = true;
      }
      emit('loaded', { entry: entryUrl });
    } catch (err) {
      emit('error', { message: String((err && err.message) || err) });
    }
  }

  function setExpression(id) {
    if (!model) return;
    try {
      if (!id) {
        const mgr = model.internalModel.motionManager.expressionManager;
        if (mgr && mgr.resetExpression) mgr.resetExpression();
        return;
      }
      model.expression(id);
    } catch (err) {
      emit('error', { message: 'expression: ' + String(err) });
    }
  }

  function startMotion(group, index, priority) {
    if (!model) return;
    try {
      // 库的优先级语义：0=IDLE / 1=NORMAL / 2=FORCE，环境 Idle 循环
      // 占用 NORMAL，同优先级动作会被拒绝（"equivalent or higher
      // priority"）。显式指令（预览/映射/情绪触发）一律 FORCE 打断。
      model.motion(group, Number(index) || 0, 2);
    } catch (err) {
      emit('error', { message: 'motion: ' + String(err) });
    }
  }

  function applyLip(v) {
    try {
      model.internalModel.coreModel.setParameterValueById('ParamMouthOpenY', v);
    } catch (e) { /* ignore */ }
  }

  function setLipSync(value) {
    if (!model) return;
    const v = Math.max(0, Math.min(1, Number(value) || 0));
    applyLip(v);
    if (lipTimer) clearTimeout(lipTimer);
    // 一段时间无新指令自动闭嘴（TTS 句间静默也靠这个回落）。
    lipTimer = setTimeout(() => applyLip(0), 250);
  }

  function setPointer(x, y) {
    if (!model) return;
    try {
      const core = model.internalModel.coreModel;
      core.setParameterValueById('ParamAngleX', (Number(x) - 0.5) * 30);
      core.setParameterValueById('ParamAngleY', (0.5 - Number(y)) * 30);
      core.setParameterValueById('ParamEyeBallX', (Number(x) - 0.5) * 2);
      core.setParameterValueById('ParamEyeBallY', (0.5 - Number(y)) * 2);
    } catch (e) { /* ignore */ }
  }

  return {
    loadModel,
    setExpression,
    startMotion,
    setLipSync,
    setPointer,
    isReady: () => !!model,
  };
})();

window.petHost = petHost;

// 页面就绪即通知 Dart。
if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
  window.flutter_inappwebview.callHandler(
    'petBridge', JSON.stringify({ event: 'ready' }));
}
