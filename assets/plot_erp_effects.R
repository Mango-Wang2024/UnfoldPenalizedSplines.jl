args <- commandArgs(trailingOnly = TRUE)
curves <- read.csv(file.path(args[1], "curves.csv"))
levels <- sort(unique(curves$x1))
color_map <- colorRampPalette(c("#7E1B02", "#9D5A17", "#B78C32", "#CFCA73",
                               "#BFEAC3", "#77D1D7", "#399DC6", "#236BB1",
                               "#063499"))
palette <- color_map(length(levels))
limits <- c(-6.5, 10.5)
png(args[2], width = 1800, height = 780, res = 150, pointsize = 18)
layout(matrix(1:3, nrow = 1), widths = c(1, 1, 0.13))

methods <- c("Unpenalized", "REML")
titles <- c("(a) Fixed basis, unpenalized", "(b) REML-selected smoothing")
for (panel in seq_along(methods)) {
  par(mar = c(4.4, 4.5, 3.2, 0.8), mgp = c(2.7, 0.65, 0), tcl = -0.25,
      family = "Arial", font = 1, font.axis = 1, font.lab = 1,
      cex.axis = 1, cex.lab = 1, las = 1, bty = "l")
  plot(NA, xlim = c(-0.1, 0.5), ylim = limits, xlab = "Time [s]",
       ylab = if (panel == 1) "Voltage [\u00b5V]" else "",
       axes = FALSE, xaxs = "i")
  axis(1, at = c(0, 0.2, 0.4), labels = c("0.0", "0.2", "0.4"))
  voltage_ticks <- seq(-3, 9, by = 3)
  axis(2, at = voltage_ticks, labels = formatC(voltage_ticks, format = "f", digits = 1))
  for (j in seq_along(levels)) {
    line <- curves[curves$method == methods[panel] & curves$x1 == levels[j], ]
    line <- line[order(line$time), ]
    lines(line$time, line$yhat, col = palette[j], lwd = 1.6)
  }
  box(bty = "l", lwd = 0.8)
  title(titles[panel], adj = 0, line = 1.5, cex.main = 1, font.main = 1)
  mtext("k = 8 per predictor", side = 3, line = 0.2, adj = 0,
        cex = par("cex") * 0.8, col = "grey35")
}

par(mar = c(4.4, 0.3, 3.2, 2.7), mgp = c(2, 0.6, 0), tcl = -0.25,
    family = "Arial", font = 1, font.axis = 1, cex.axis = 1, las = 1)
plot(NA, xlim = c(0, 1), ylim = range(levels), axes = FALSE,
     xlab = "", ylab = "", xaxs = "i", yaxs = "i")
gradient <- color_map(1024)
edges <- seq(min(levels), max(levels), length.out = length(gradient) + 1)
rect(0, head(edges, -1), 1, tail(edges, -1), col = gradient, border = NA)
axis(4, at = c(-2, 0, 2))
box(lwd = 0.8)
mtext(expression(x[1]), side = 3, line = 0.8, cex = par("cex"))
dev.off()
