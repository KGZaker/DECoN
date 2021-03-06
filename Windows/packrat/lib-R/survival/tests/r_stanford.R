options(na.action=na.exclude) # preserve missings
options(contrasts=c('contr.treatment', 'contr.poly')) #ensure constrast type
library(survival)

#
# The Stanford data from 1980 is used in Escobar and Meeker, Biometrics 1992.
#	t5 = T5 mismatch score
#  Their case numbers correspond to a data set sorted by age
#
aeq <- function(x,y, ...) all.equal(as.vector(x), as.vector(y), ...)

stanford2$t5 <- ifelse(stanford2$t5 <0, NA, stanford2$t5)
stanford2 <- stanford2[order(stanford2$age, stanford2$time),]
stanford2$time <- ifelse(stanford2$time==0, .5, stanford2$time)

cage <- stanford2$age - mean(stanford2$age)
fit1 <- survreg(Surv(time, status) ~ cage + I(cage^2), stanford2,
		dist='lognormal')
fit1
ldcase <- resid(fit1, type='ldcase')
ldresp <- resid(fit1, type='ldresp')
# The ldcase and ldresp should be compared to table 1 in Escobar and 
#  Meeker, Biometrics 1992, p519; the colums they label as (1/2) A_{ii}
#  They give data for selected cases, entered below as mdata
mdata <- cbind(c(1,2,4,5,12,16,23,61,66,72,172,182,183,184),
               c(.035, .244, .141, .159, .194, .402, 0,0, .143, .403,
                 .178, .033, .005, .015),
               c(.138, .145, .073, .076, .104, .159, 0,0, .109, .184,
                 .116, .063, .103, .144))
dimnames(mdata) <- list(NULL, c("case#", "ldcase", "ldresp"))
aeq(round(ldcase[mdata[,1]],3), mdata[,2])
aeq(round(ldresp[mdata[,1]],3), mdata[,3])             

plot1 <- function() {
    # make their figure 1, 2, and 6
    temp <- predict(fit1, type='quantile', p=c(.1, .5, .9)) 
    plot(stanford2$age, stanford2$time, log='y', xlab="Age", ylab="Days",
	 ylim=range(stanford2$time, temp))
    matlines(stanford2$age, temp, lty=c(1,2,2), col=1)

    n <- length(ldcase)
    plot(1:n, ldcase, xlab="Case Number", ylab="(1/2) A", type='l')
    title (main="Case weight pertubations")
    plot(1:n, ldresp, xlab="Case Number", ylab="(1/2) A", 
         ylim=c(0, .2), type='l')
    title(main="Response pertubations")
    indx <- which(ldresp > .07)
    text(indx, ldresp[indx]+ .005, indx%%10, cex=.6)
    }

postscript('meekerplot.ps')
plot1()
dev.off()
#
# Stanford predictions in other ways
#
fit2 <- survreg(Surv(time, status) ~ poly(age,2), stanford2,
		dist='lognormal')

p1 <- predict(fit1, type='response')
p2 <- predict(fit2, type='response')
aeq(p1, p2)

p3 <- predict(fit2, type='terms', se=T)
p4 <- predict(fit2, type='lp', se=T)
p5 <- predict(fit1, type='lp', se=T)
# aeq(p3$fit + attr(p3$fit, 'constant'), p4$fit)  #R is missing the attribute
aeq(p4$fit, p5$fit)
aeq(p3$se.fit, p4$se.fit)  #this one should be false
aeq(p4$se.fit, p5$se.fit)  #this one true

