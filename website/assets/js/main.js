/* 心语 · ineermost_words — 交互脚本（无依赖） */
(() => {
  "use strict";

  const doc = document;
  const root = doc.documentElement;
  const THEMES = ["violet", "sakura", "azure", "mint", "daylight"];
  const STORE_KEY = "xinyu-theme";

  /* ---------- 主题切换 ---------- */
  const swatches = Array.from(doc.querySelectorAll("[data-theme-set]"));

  function applyTheme(name, { persist = true } = {}) {
    const theme = THEMES.includes(name) ? name : "violet";
    root.dataset.theme = theme;
    swatches.forEach((btn) => {
      const on = btn.dataset.themeSet === theme;
      btn.classList.toggle("is-active", on);
      btn.setAttribute("aria-pressed", String(on));
    });
    const meta = doc.querySelector('meta[name="theme-color"]');
    if (meta) {
      meta.setAttribute(
        "content",
        theme === "daylight" ? "#F6F4FB" : getComputedStyle(root).getPropertyValue("--bg").trim() || "#07060F"
      );
    }
    if (persist) {
      try {
        localStorage.setItem(STORE_KEY, theme);
      } catch {
        /* 隐私模式下忽略 */
      }
    }
  }

  let saved = null;
  try {
    saved = localStorage.getItem(STORE_KEY);
  } catch {
    saved = null;
  }
  applyTheme(saved || "violet", { persist: false });

  swatches.forEach((btn) => {
    btn.addEventListener("click", () => applyTheme(btn.dataset.themeSet));
  });

  /* ---------- 导航 ---------- */
  const nav = doc.getElementById("nav");
  const links = doc.getElementById("navLinks");
  const toggle = doc.getElementById("navToggle");

  const onScroll = () => nav && nav.classList.toggle("is-scrolled", window.scrollY > 10);
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  function closeMenu() {
    if (!links) return;
    links.classList.remove("is-open");
    toggle?.setAttribute("aria-expanded", "false");
  }

  toggle?.addEventListener("click", () => {
    const open = links.classList.toggle("is-open");
    toggle.setAttribute("aria-expanded", String(open));
  });

  links?.addEventListener("click", (event) => {
    if (event.target.closest("a")) closeMenu();
  });

  doc.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeMenu();
  });

  /* ---------- 滚动入场 ---------- */
  const revealables = Array.from(doc.querySelectorAll(".reveal"));
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-in");
          io.unobserve(entry.target);
        });
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.08 }
    );
    revealables.forEach((el) => io.observe(el));
  } else {
    revealables.forEach((el) => el.classList.add("is-in"));
  }

  /* ---------- 年份 ---------- */
  const year = doc.getElementById("year");
  if (year) year.textContent = String(new Date().getFullYear());

  /* ---------- 安卓设备提示 ---------- */
  const toast = doc.getElementById("toast");
  const isAndroid = /android/i.test(navigator.userAgent);
  let toastTimer = 0;

  function hideToast() {
    if (!toast) return;
    toast.classList.remove("is-on");
    window.clearTimeout(toastTimer);
  }

  if (toast && isAndroid) {
    toastTimer = window.setTimeout(() => toast.classList.add("is-on"), 2600);
    doc.querySelector("[data-toast-close]")?.addEventListener("click", hideToast);
    window.setTimeout(hideToast, 14000);
  }

  /* ---------- 锚点平滑滚动兜底（旧浏览器） ---------- */
  if (!("scrollBehavior" in root.style)) {
    doc.querySelectorAll('a[href^="#"]').forEach((a) => {
      a.addEventListener("click", (event) => {
        const id = a.getAttribute("href");
        if (!id || id === "#") return;
        const target = doc.querySelector(id);
        if (!target) return;
        event.preventDefault();
        window.scrollTo({ top: target.getBoundingClientRect().top + window.scrollY - 80 });
      });
    });
  }
})();
