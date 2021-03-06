#dados <- read.csv2("https://pastebin.com/raw/6GHshnm0", header=T, sep = "\t")

lad <- function (dados) {
  combinations <- combn(c(1:nrow(dados)),2); aux <- vector(mode = "list", length = 6)
  aux[[1]] <- double(ncol(combinations)); aux[[2]] <- double(ncol(combinations))
  for(i in seq(1, ncol(combinations))){
    y <- matrix(nrow=2, ncol=1); x <- matrix(nrow=2, ncol=2)
    y[1,1] <- as.numeric(dados[combinations[,i][1],][1])
    y[2,1] <- as.numeric(dados[combinations[,i][2],][1])
    x[c(1,2),1] <-c(1,1)
    x[1,2] <- as.numeric(dados[combinations[,i][1],][2])
    x[2,2] <- as.numeric(dados[combinations[,i][2],][2])
    if(x[1,2] == x[2,2]){
      aux[[1]] <- aux[[1]][-i]
      aux[[2]] <- aux[[2]][-i]} else {
        aux[[1]][i] <- solve(x,y, tol = 1e-17)[1]
        aux[[2]][i] <- solve(x,y, tol = 1e-17)[2]}}
  aux[[3]] <- numeric(length(aux[[2]]))
  for(i in 1:length(aux[[2]])){aux[[3]][i] <- sum(abs(dados[,1] - (aux[[1]][i]+aux[[2]][i]*dados[,2])))}
  aux[[4]] <- matrix(ncol = 3, nrow=length(aux[[1]]))
  aux[[4]][,1] <- aux[[1]]; aux[[4]][,2] <- aux[[2]]; aux[[4]][,3] <- aux[[3]]
  aux[[5]] <- numeric(1); aux[[6]] <- numeric(1)
  aux[[5]][1] <- as.numeric(aux[[4]][which.min(aux[[4]][,3]),][1])
  aux[[6]][1] <- as.numeric(aux[[4]][which.min(aux[[4]][,3]),][2])
  out <- list(); out$salve <- cat("Universidade Federal de Minas Gerais \nRegressão não paramétrica: LAD\n\n")
  out$original.x <- dados[,2]; out$original.y <- dados[,1]
  out$fitted.values <- aux[[5]] + aux[[6]] * dados[,2]
  out$residuals <- (aux[[5]] + aux[[6]] * dados[,2]) - dados[,1] 
  out$modeloEscolhido <- cbind(aux[[4]][which.min(aux[[4]][,3]),][1],aux[[4]][which.min(aux[[4]][,3]),][2],aux[[4]][which.min(aux[[4]][,3]),][3])
  colnames(out$modeloEscolhido) <- c("Intercepto","Inclinação","Soma_residuos")
  return(out)
}

rreg <- function (dados) {
  library(dplyr) #### requires this library
  combinations <- combn(c(1:nrow(dados)),2); aux <- vector(mode = "list", length = 9)
  aux[[1]] <- numeric(ncol(combinations)); aux[[2]] <- numeric(ncol(combinations))
  aux[[3]] <- numeric(ncol(combinations))
  for(i in seq(1, ncol(combinations))){
    aux[[5]] <- matrix(nrow=2, ncol=1); aux[[6]] <- matrix(nrow=2, ncol=2)
    aux[[5]][1,1] <- as.numeric(dados[combinations[,i][1],][1])
    aux[[5]][2,1] <- as.numeric(dados[combinations[,i][2],][1])
    aux[[6]][c(1,2),1] <-c(1,1)
    aux[[6]][1,2] <- as.numeric(dados[combinations[,i][1],][2])
    aux[[6]][2,2] <- as.numeric(dados[combinations[,i][2],][2])
    if(aux[[6]][1,2] == aux[[6]][2,2]){
      aux[[1]] <- aux[[1]][-i]
      aux[[2]] <- aux[[2]][-i]
      aux[[3]] <- aux[[3]][-i]} else {
        aux[[1]][i] <- solve(aux[[6]],aux[[5]], tol = 1e-17)[1]
        aux[[2]][i] <- solve(aux[[6]],aux[[5]], tol = 1e-17)[2] 
        aux[[3]][i] <-  as.numeric(abs(aux[[6]][1,2] - aux[[6]][2,2]))}}
  out <- list(); aux[[7]] <- data.frame(aux[[1]], aux[[2]], aux[[3]]); aux[[7]] <- aux[[7]] %>% arrange(aux[[2]]) 
  aux[[7]] <- cbind(aux[[7]], cumsum(aux[[7]][,3]/sum(aux[[3]])))
  aux[[7]] <- aux[[7]] %>% filter((aux[[2]] != 00))
  colnames(aux[[7]]) <- c("Intercepto","Inclinação","Distancia","pesoacum")
  aux[[8]] <- filter(aux[[7]], pesoacum>0.5)[1,2]; aux[[9]] <- double(nrow(dados))
  for(i in seq(1, nrow(dados))){aux[[9]][i] <- as.numeric(dados[i,][1] - aux[[8]] * dados[i,][2])}
  aux[[10]] <- median(aux[[9]])
  out$salve <- cat("Universidade Federal de Minas Gerais \nRegressão não paramétrica: Rank-Regression\n\n")
  out$original.x <- dados[,2]; out$original.y <- dados[,1]
  out$fitted.values <- aux[[10]] + aux[[8]] * dados[,2]
  out$residuals <- (aux[[10]] + aux[[8]] * dados[,2]) - dados[,1] 
  out$modeloEscolhido <- cbind(aux[[10]], aux[[8]])
  colnames(out$modeloEscolhido) <- c("Intercepto","Inclinação")
  return(out)
}

btlad <- function(lad_inicial, repeticoes){
  aux <- vector(mode = "list", length = 3); aux[[1]] <- double(repeticoes)
  y <- mean(lad_inicial$original.y)
  for(i in seq(1, repeticoes)){
    aux[[2]] <- sample(lad_inicial$residuals, length(lad_inicial$residuals), replace = T)
    aux[[3]] <- y + aux[[2]]; cat("Calculando..", i,"/",repeticoes, "\n")
    aux[[1]][i] <- as.numeric(lad(data.frame(aux[[3]], lad_inicial$original.x))$modeloEscolhido[2])
  }
  return(list('repeticoes' = repeticoes, 'qt' = c(quantile(aux[[1]], .025), quantile(aux[[1]], 0.975)), 'betas' = aux[[1]]))
}

btrreg <- function(rreg_inicial, repeticoes){
  aux <- vector(mode = "list", length = 3); aux[[1]] <- double(repeticoes)
  y <- mean(rreg_inicial$original.y)
  for(i in seq(1, repeticoes)){
    aux[[2]] <- sample(rreg_inicial$residuals, length(rreg_inicial$residuals), replace = T)
    aux[[3]] <- y + aux[[2]]; cat("Calculando..", i,"/",repeticoes, "\n")
    aux[[1]][i] <- as.numeric(rreg(data.frame(aux[[3]], rreg_inicial$original.x))$modeloEscolhido[2])
  }
  return(list('Repeticoes' = repeticoes, 'qt' = c(quantile(aux[[1]], .025), quantile(aux[[1]], 0.975)), 'betas' = aux[[1]]))
}
