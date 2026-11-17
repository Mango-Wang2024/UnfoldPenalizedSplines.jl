args <- commandArgs(trailingOnly = TRUE)
curves <- read.csv(file.path(args[1], "curves.csv"))
levels <- sort(unique(curves$x1))
palette <- colorRampPalette(c("#8C2D04", "#BD8B23", "#F4F5B2", "#BDE6C5", "#4CB4CF", "#08306B"))(length(levels))
limits <- range(curves$yhat)
limits <- limits + c(-0.4, 0.5)
png(args[2], width = 1800, height = 780, res = 150, pointsize = 13)
layout(matrix(1:3, nrow = 1), widths = c(1, 1, 0.14))

methods <- c("Unpenalized", "REML")
titles <- c("(a) Fixed basis, unpenalized", "(b) REML-selected smoothing")
for (panel in seq_along(methods)) {
  par(mar = c(4.4, 4.5, 3.2, 0.8), mgp = c(2.7, 0.65, 0), tcl = -0.25,
      family = "sans", las = 1, bty = "l")
  plot(NA, xlim = c(-0.1, 0.5), ylim = limits, xlab = "Time [s]",
       ylab = if (panel == 1) "Predicted voltage [\u00b5V]" else "",
       axes = FALSE, xaxs = "i")
  axis(1, at = seq(-0.1, 0.5, by = 0.1))
  axis(2, at = pretty(limits, n = 5))
  abline(v = 0, lty = 3, col = "grey75", lwd = 0.7)
  abline(h = 0, col = "grey90", lwd = 0.7)
  for (j in seq_along(levels)) {
    line <- curves[curves$method == methods[panel] & curves$x1 == levels[j], ]
    line <- line[order(line$time), ]
    lines(line$time, line$yhat, col = palette[j], lwd = 1.6)
  }
  box(bty = "l", lwd = 0.8)
  title(titles[panel], adj = 0, line = 1.5, cex.main = 1.02, font.main = 2)
  mtext("k = 8 per predictor", side = 3, line = 0.2, adj = 0, cex = 0.8, col = "grey35")
}

par(mar = c(4.4, 0.3, 3.2, 2.7), mgp = c(2, 0.6, 0), tcl = -0.25, las = 1)
plot(NA, xlim = c(0, 1), ylim = range(levels), axes = FALSE,
     xlab = "", ylab = "", xaxs = "i", yaxs = "i")
edges <- seq(min(levels), max(levels), length.out = length(levels) + 1)
rect(0, head(edges, -1), 1, tail(edges, -1), col = palette, border = NA)
axis(4, at = c(-2, 0, 2))
box(lwd = 0.8)
mtext(expression(x[1]), side = 3, line = 0.8, cex = 1.05)
dev.off()
