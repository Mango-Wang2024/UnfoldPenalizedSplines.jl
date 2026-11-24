(() => {
  // The .htm demo avoids MultiDocumenter's navigation injection into HTML pages.
  const frame = document.getElementById("spline-smoothing-demo");
  frame.addEventListener("load", () => {
    const body = frame.contentDocument.body;
    const resize = () => {
      frame.style.height = `${body.scrollHeight}px`;
    };
    new ResizeObserver(resize).observe(body);
    resize();
  });
})();
