#include <Rcpp.h>
using namespace Rcpp;


// Gompertz Distribution
// [[Rcpp::export]]
double qgompertzC (double p, double shape, double rate) {
  double q = 0;
  if (shape == 0){
    q = R::qexp(p, rate, 1, 0);
  }
  else if (shape < 0){
    q = INFINITY;
  }
  else {
    q = 1/shape * log(1 - shape * log(1 - p)/rate);
  }
  return q;
}

// [[Rcpp::export]]
double rgompertzC (double shape, double rate){
  double u = R::runif(0,1);
  return qgompertzC(u, shape, rate);
}

// Random Survival Times
// [[Rcpp::export]]
double rsurv(double location, double par2, std::string dist) {
  double surv = 0.0;
  if (dist == "exponential"){
    double rate = exp(location);
    surv = R::rexp(1/rate);
  }
  else if (dist == "weibull"){
    double shape = exp(par2);
    double scale = exp(location);
    surv = R::rweibull(shape, scale);
  }
  else if (dist == "gompertz"){
    double shape = exp(par2);
    double rate = exp(location);
    surv = rgompertzC(shape, rate);
  }
  return surv;
}

/*** R
n <- 1000
r1 <- replicate(n, rGompertz(1, 1))
r2 <- rgompertz(1000, 1, 1)
summary(r1)
summary(r2)
  */

