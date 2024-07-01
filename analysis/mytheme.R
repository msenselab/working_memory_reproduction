#color configuration
colorSet3 <- scale_color_manual(values=c("#999999", "#E69F00", "#56B4E9")) 
colorSet4 <- scale_color_manual(values=c("#999999", "#E69F00", "#56B4E9", "#1a9641")) 
colorSet <- scale_color_manual(values=c("#d7191c", "#fdae61", "#a6d96a", "#1a9641")) 
colorSet5 <- scale_color_manual(values=c("#999999", "#E69F00", "#56B4E9", "#1a9641", "#d7191c")) 
fillSet3 <- scale_fill_manual(values=c("#999999", "#E69F00", "#56B4E9"))

#customize theme
theme_new <- theme_bw() + 
  theme(panel.border = element_blank(), 
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), 
        axis.line = element_line(colour = "black"),
        strip.background = element_rect(color = "white", fill = "white"),
        panel.grid = element_blank())