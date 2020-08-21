theme_plots = function(...){
  theme_minimal() +
    theme(
      # plot title
      plot.title=element_text(face = "bold", size=25, vjust=0, hjust = 0.5, family="LM Roman 10"),  
      
      # axis
      axis.title.x  = element_text(face = "bold", size=20, color = "black", family="LM Roman 10"),
      axis.title.y  = element_blank(),
      #axis.title.y  = element_text(vjust=-1, size =14, family="Times New Roman"), 
      
      axis.text.x   = element_text(size=15, color = "black", vjust=0.5, margin=margin(-15,0,0,0)),
      axis.text.y   = element_text(size=15, color = "black"),
      
      # legend
      legend.text       = element_text(size = 22, family="LM Roman 10"),
      legend.title      = element_blank(),
      
      legend.direction = 'horizontal', 
      legend.position = 'bottom',
      legend.key.size = unit(2.5, 'lines'),
      legend.spacing.x = unit(1, 'lines'))
}