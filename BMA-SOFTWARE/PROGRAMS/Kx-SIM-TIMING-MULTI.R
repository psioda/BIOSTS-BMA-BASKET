options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
node.idx = as.numeric(args[1]);


if (.Platform$OS.type == "windows") { node.idx = 1 }

if (.Platform$OS.type == "windows") { root.path = "C:/Users/psioda/Documents/GitHub/BIOSTS-BMA-BASKET/BMA-SOFTWARE/SOURCE";   }
if (.Platform$OS.type == "unix")    { root.path = "/proj/psiodalab/projects/BMA/SOURCE";                                                  }

setwd(root.path);
source("./bma.rcpp");


if (.Platform$OS.type == "windows") { root.path = "C:/Users/psioda/Documents/GitHub/BIOSTS-BMA-BASKET/BMA-SOFTWARE/RESULTS_TIMING";  }
if (.Platform$OS.type == "unix")    { root.path = "/proj/psiodalab/projects/BMA/RESULTS_TIMING";                                                 }

setwd(root.path);

nSims     = 10000;                     
aParms    = c(0.01,0.0000000001);
 
mu0       = 0.45;
phi0      = 1.00;
ppEffCrit = 0.985;
ppFutCrit = 0.2750;
pmp.scale = 2;
n1        = 7
n2        = 16
futOnly   = 1;
K0        = rep(c(4,5,6,7,8,9,10,11,12),25);
parms     = expand.grid(mu0,phi0,ppEffCrit,ppFutCrit,pmp.scale,n1,n2,futOnly,K0);


head(parms);

nPerNode = 1;
nrow(parms)/nPerNode;

set.start = 1  + nPerNode *(node.idx-1)
set.stop  = min(nPerNode *(node.idx),nrow(parms))


parms = parms[seq(set.start,set.stop),];
nParmSettings = nrow(parms);

set.seed(node.idx);



     for (idx in (1:nParmSettings))
     {

	row = 0;
	K0 = parms[idx,9];
 
	rTarg     = 0.45;
      rNull     = 0.15;
      rRatesMod = matrix(rNull,(K0+1),K0);

	for (i in 1:K0)  
	{
		rRatesMod[(i+1):(K0+1),i]= rTarg     
	}

	mu0  = parms[idx,1];
     	phi0 = parms[idx,2];
          
 
	ppEffCrit = rep(parms[idx,3],K0);
	ppFutCrit = rep(parms[idx,4],K0);

      pmp0 = parms[idx,5];

      targSSPer    = c(parms[idx,6],parms[idx,7]) ;

      futOnly      = parms[idx,8];

      nInterim     = 2;

      mss = 4;
		
      minSSFut     = mss;  ## minimum number of subjects in basket to assess futility using BMA;
      minSSEff     = mss;  ## minimum number of subjects in basket to assess activity using BMA;

      minSSEnr     = matrix(rep(mss,K0),nrow=nInterim,ncol=K0,byrow=T); ## minimum # of new subjects per basket before next analysis - each row is an interim;

      maxSSEnr     = matrix(rep(100,K0),nrow=nInterim,ncol=K0,byrow=T); ## maximum # of new subjects per basket before next analysis - each row is an interim;


	rRatesNull    = rep(rNull,K0);
	rRatesMid     = rep(rTarg,K0);
 		
      	for (s in c(1.0,0.5,2.0))
     		{

			if (s==2.0) { eRatesMod = rep(1,K0); } else { eRatesMod = rep(2,K0);  }

			.s = 0;
			.e = K0;


      		for (i in .s:.e)  
      		{
				start.time = proc.time();
        			if (i>=1 & i<=K0) { eRatesMod[i] = eRatesMod[i]*s } else if (i>K0) { eRatesMod = rep(2,K0); }
           			x <- BMA_Design(nSims,eRatesMod,rRatesMod[i+1,],aParms,ppEffCrit,ppFutCrit,futOnly,
                           			rRatesNull,rRatesMid,minSSFut,minSSEff,minSSEnr,maxSSEnr,targSSPer,nInterim,
                          			pmp0,mu0,phi0);

          			row = row +1;
				rr = as.data.frame(rbind(rRatesMod[i+1,]));
                        
				stop.time    = proc.time();
				elapsed.time = (stop.time-start.time)/60
				elapsed.time = elapsed.time[[3]];

          			parm.sim = cbind(mss,parms[idx ,],s,sum(rRatesMod[i+1,]>rNull),rr,elapsed.time );
          			colnames(parm.sim) <- c("mss","mu0","phi0","ppEffCrit","ppFutCrit","pmp","n1_targ","n2_targ","futOnly","K0","enrScale","numAlt",paste("trr",seq(1,K0),sep=""),"elapsed_time");

          			if (row ==1) { y = cbind(parm.sim,rbind(unlist(x)))
          			} else         y = rbind(y,cbind(parm.sim,rbind(unlist(x))))

       		}
		}
  	}


names = colnames(y)
names.new = gsub("point.estimation.PM.ave",                  "PM",names)
names.new = gsub("point.estimation.SP.ave",                  "SP",names.new)
names.new = gsub("point.estimation.PP.ave",                  "PP",names.new)
names.new = gsub("point.estimation.bias",                    "BIAS",names.new)
names.new = gsub("point.estimation.mse",                     "MSE",names.new)

names.new = gsub("hypothesis.testing.rr",                    "rr",names.new)
names.new = gsub("hypothesis.testing.fut",                   "fut",names.new)
names.new = gsub("hypothesis.testing.fw.fpr",                "FWER",names.new)
names.new = gsub("hypothesis.testing.nerr",                  "nerr",names.new)


names.new = gsub("sample.size.basket.ave",                   "aveSS",names.new)
names.new = gsub("sample.size.basket.med",                   "medSS",names.new)
names.new = gsub("sample.size.basket.min",                   "minSS",names.new)
names.new = gsub("sample.size.basket.max",                   "maxSS",names.new)
names.new = gsub("sample.size.overall.ave",                  "aveSSovr",names.new)
names.new = gsub("sample.size.overall.med",                  "medSSovr",names.new)
names.new = gsub("sample.size.overall.min",                  "minSSovr",names.new)
names.new = gsub("sample.size.overall.max",                  "maxSSovr",names.new)

names.new = gsub("trial.duration.average",                  "aveDur",names.new)
names.new = gsub("trial.duration.median" ,                  "medDur",names.new)
names.new = gsub("trial.duration.maximum",                  "maxDur",names.new)
names.new = gsub("trial.duration.minimum",                  "minDur",names.new)

names.new = gsub("early.stopping.interim.stop.prob",        "esProb",names.new)
names.new = gsub("early.stopping.baskets.continuing.ave",   "nbCont",names.new)



colnames(y) <- names.new;
rownames(y) <- NULL;

name = paste("./K",K0,"-DESIGN-TIMING-MULTI-",formatC(node.idx, width = 4, format = "d", flag = "0"),".CSV",sep="")
write.csv(y,file=name ,row.names=F)






