#########################
### attack rate plots ###
#########################
### read in output files
library(data.table)
library(ggExtra)
setwd("~/Dropbox/Kylie/Projects/Morevac/data/attack_rates")
files1 = list.files(pattern="*.csv")
dt_ar = do.call(rbind, lapply(files1, fread))[,-1]

# create AR difference and AR ratio variables
dt_ar_sub <- dt_ar[dt_ar$Vac_Strategy == "Annual",]
dt_ar_sub$Diff <- dt_ar[dt_ar$Vac_Strategy == "Annual",3] - dt_ar[dt_ar$Vac_Strategy == "Every Other Year",3]
dt_ar_sub$Ratio <- dt_ar[dt_ar$Vac_Strategy == "Annual",3] / dt_ar[dt_ar$Vac_Strategy == "Every Other Year",3]

### heatmap
# for better heatmap resolution, round parameter values
dt_ar2 <- cbind(dt_ar[,1:2],round(dt_ar[,c(3:11)],2)) # round to 2 decimal places
dt_ar3 <- cbind(dt_ar[,1:3],round(dt_ar[,c(3:11)],1)) # round to 1 decimal place

p_heat2 <- ggplot(dt_ar2[dt_ar2$Vac_Strategy!="No Vaccination"], aes(x = VE, y = Vac_Cov, fill = Attack_Rate)) +
  geom_tile(alpha=0.2) +
  viridis::scale_fill_viridis() +
  #facet_wrap(~Age) +
  facet_grid(Vac_Strategy ~ Age) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())
p_heat2

png(file = "ar_heatmap_VE_vs_VacCov.png", width = 8, units = 'in')
p_heat2
dev.off()

### heatmap using ratio: annual AR / biennial AR
# create new ratio variable
p_heat_ratio <- ggplot(dt_ar2_sub1, aes(x = VE, y = Waning, fill = Ratio)) +
  geom_tile(alpha=0.2) +
  viridis::scale_fill_viridis() +
  facet_wrap(~Age) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
  )
p_heat_ratio

### spaghetti plot
# create group variable for each unique set of parameter values
library(dplyr)
dt_ar <- dt_ar %>%
  mutate(ID = group_indices(., Vac_Cov, Waning,Take,Epsilon,Rho,VE),
         EpsilonGroup = cut(Epsilon, breaks = 5,
                            labels = c("<0.1","[0.1,0.2)","[0.2,0.3)","[0.3,0.4)","[0.4,0.5)")))

p_spaghetti <- ggplot(dt_ar, aes(x = Age, y = Attack_Rate, group = ID, color = ID)) +
  geom_line() + viridis::scale_fill_viridis() +
  facet_grid(Vac_Strategy ~ EpsilonGroup) +
  theme(legend.position = "none")
p_spaghetti

png(file = "ar_spaghetti_epsilongroup2.png")
p_spaghetti
dev.off()

### univariate scatter plots
p1 <- ggplot(data = dt_ar_sub, aes(x = VE, y = Diff,color = Diff)) +
  geom_point() +
  viridis::scale_color_viridis() +
  geom_hline(yintercept = 0) +
  #xlab('VE') +
  ylab('Difference in Attack Rate') +
  #scale_x_continuous(labels = c(0,.01,.02,.03,.04,.05))+
  facet_wrap(~Age)
p1

png(file = "ar_diff_scatter_ve.png", width = 10, height = 8,
    units = "in", pointsize = 8, res = 300)
p1
dev.off()

### bivariate scatter plots
p2 <- ggplot(data = dt_ar_sub, aes(x = Rho, y = Vac_Cov, color = Diff)) +
  geom_point() +
  viridis::scale_color_viridis() +
  facet_wrap(~Age) +
  ylab("Correlation of Vaccination (Rho)") +
  labs(color = "Difference") +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(colour = "black")
  )
p2

png(file = "ar_diff_scatter_rho+vaccov.png", width = 10, height = 8,
    units = "in", pointsize = 8, res = 300)
p2
dev.off()

### Miscallaneous
legend_x <- 0.25
legend_y <- 0.95
tmp$Num_Vacs <- factor(tmp$Num_Vacs)
p2 <- ggplot(tmp, aes(x = Num_Vacs, y = mean, fill = Vac_Strategy)) +
  geom_boxplot() +
  ylab('Number of Lifetime Infections') +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(colour = "black"),
        legend.position = c(legend_x, legend_y),
        legend.justification = c("right", "top"),
        legend.box.just = "right",
        legend.margin = margin(6, 6, 6, 6),
        legend.key = element_rect(fill = "white")
  )
p2
# theme_set(theme_cowplot(font_size=10)) # reduce default font size
# p_combined <- plot_grid(p1, p2, labels = "AUTO", ncol = 1, align = 'v', axis = 'l')

png(file = "rolling_cohort_off_at_10_sim500.png")
p1
dev.off()

# p1 <- p1 + theme(panel.grid.major = element_blank(),
#                  panel.grid.minor = element_blank(),
#                  panel.background = element_blank(),
#                  axis.line = element_line(colour = "black"),
#                  legend.position = c(legend_x, legend_y),
#                  legend.justification = c("right", "top"),
#                  legend.box.just = "right",
#                  legend.margin = margin(6, 6, 6, 6),
#                  legend.key = element_rect(fill = "white"))
# p1
