# PartSurvCurves ---------------------------------------------------------------

#' Form \code{PartSurvCurves} object
#' 
#' \code{form_PartSurvCurves} is a generic function for forming an object of class
#' \code{\link{PartSurvCurves}} from a fitted statistical model.
#' @param object An object of class \code{\link{partsurvfit}}.
#' @param data An object of class "expanded_hesim_data" returned by 
#' \code{\link{expand_hesim_data}}. Must be expanded by the data tables "strategies" and
#' "patients". 
#' @param n Number of random observations of the parameters to draw.
#' @param point_estimate If \code{TRUE}, then the point estimates are returned and and no samples are drawn.
#' @param bootstrap If TRUE, then \code{n} bootstrap replications are drawn by refitting the survival
#'  models in \code{object} on resamples of the sample data; if FALSE, then the parameters for each survival
#'  model are independently draw from multivariate normal distributions.  
#' @param ... Further arguments passed to or from other methods. Currently unused. 
#' @return Returns an \code{\link{R6Class}} object of class \code{\link{PartSurvCurves}}.
#' @export
form_PartSurvCurves <- function(object, data, n = 1000, point_estimate = FALSE,
                                bootstrap = TRUE){
  if (!inherits(object, c("partsurvfit"))){
    stop("'Object' must be of class 'partsurvfit'.")
  }
  input.data <- form_input_data(object, data, id_vars = c("strategy_id", "patient_id"))
  params <- form_params(object, n = n, point_estimate = point_estimate, bootstrap = bootstrap)
  return(PartSurvCurves$new(data = input.data, params = params))
}

# Manual documentation in PartSurvCurves.Rd
#' @export
PartSurvCurves <- R6::R6Class("PartSurvCurves",
  private = list(
    summary = function(x, type = c("hazard", "cumhazard", "survival", 
                                   "rmst", "quantile"), 
                       dr = 0){
      self$check()
      type <- match.arg(type)
      res <- data.table(C_PartSurvCurves_summary(self, x, type, dr))
      res[, curve := curve + 1]
      res[, sample := sample + 1]
      if (type %in% c("hazard", "cumhazard", "survival", "rmst")){
        setnames(res, "x", "t")
      } else if (type == "quantile"){
        setnames(res, "x", "p")
      }
      if (type == "hazard") setnames(res, "value", "hazard")
      if (type == "cumhazard") setnames(res, "value", "cumhazard")
      if (type == "survival") setnames(res, "value", "survival")
      if (type == "rmst") setnames(res, "value", "rmst")
      if (type == "quantile") setnames(res, "value", "quantile")
      return(res[])
    }
  ),                            
                              
  public = list(
    data = NULL,
    params = NULL,

    initialize = function(data, params) {
      self$data <- data
      self$params <- params
    },
    
    hazard = function(t){
      return(private$summary(x = t, type = "hazard"))
    },
    
    cumhazard = function(t){
      return(private$summary(x = t, type = "cumhazard"))
    },
    
    survival = function(t){
      return(private$summary(x = t, type = "survival"))
    },
    
    rmst = function(t, dr = 0){
      return(private$summary(x = t, type = "rmst", dr = dr))
    },
    
    quantile = function(p){
      return(private$summary(x = p, type = "quantile"))
    },
    
    check = function(){
      if(!inherits(self$data, "input_data")){
        stop("'data' must be an object of class 'input_data'",
            call. = FALSE)
      }
      if(!inherits(self$params, c("params_surv_list", 
                                  "joined_params_surv_list"))){
        stop("Class of 'params' is not supported. See documentation.",
             call. = FALSE)
      }
    }
  )
)

# PartSurvStateVals ------------------------------------------------------------
#' Form \code{PartSurvStateVals} object
#' 
#' \code{form_PartSurvStateVals} is a generic function for forming an object of class
#'  \code{\link{PartSurvStateVals}} from a fitted statistical model. 
#' @param object A fitted statistical model object of the appropriate class. Supports
#' \code{\link{lm}} and \code{\link{lm_list}}.
#' @param data An object of class "expanded_hesim_data" returned by 
#' \code{\link{expand_hesim_data}}. Must be expanded by the data tables "strategies",
#' "patients", and "states".
#' @param n Number of random observations of the parameters to draw.
#' @param point_estimate If \code{TRUE}, then the point estimates are returned and and no samples are drawn.
#' @param ... Further arguments passed to or from other methods. Currently unused. 
#' @return Returns an \code{\link{R6Class}} object of class \code{\link{PartSurvStateVals}}.
#' @export
form_PartSurvStateVals <- function(object, data, n = 1000, point_estimate = FALSE){
  if (!inherits(object, c("lm", "lm_list"))){
    stop("Class of 'object' is not supported. See documentation.",
         call. = FALSE)
  }
  if(inherits(object, "lm")){
     input.data <- form_input_data(object, data, id_vars = c("strategy_id", "patient_id", "state_id")) 
  } else{
     input.data <- form_input_data(object, data, id_vars = c("strategy_id", "patient_id")) 
  }
  params <- form_params(object, n, point_estimate)
  return(PartSurvStateVals$new(data = input.data, params = params))
}

# Manual documentation in PartSurvStateVals.Rd
#' @export
PartSurvStateVals <- R6::R6Class("PartSurvStateVals",
  public = list(
    data = NULL,
    params = NULL,

    initialize = function(data, params) {
      self$data <- data
      self$params <- params
    },
    
    predict = function(){
      self$check()
      res <- data.table(C_PartSurvStateVals_predict(self))
      res[, sample := sample + 1]
      return(res[])
    },
    
    check = function(){
      if(!inherits(self$data, "input_data")){
        stop("'data' must be an object of class 'input_data'",
            call. = FALSE)
      }
      if(!inherits(self$params, c("params_lm"))){
          stop("Class of 'params' is not supported. See documentation.",
               call. = FALSE)
      }
    }
  )
)

# PartSurv ---------------------------------------------------------------------
# Manual documentation in PartSurv.Rd
#' @export
PartSurv <- R6::R6Class("PartSurv",
  private = list(
    .t_ = NULL,
    .survival_ = NULL,
    .stateprobs_ = NULL,
    .costs_ = NULL,
    .qalys_ = NULL,
    
    sim_auc = function(dr, type){
      if(is.null(self$stateprobs_)){
        stop("You must first simulate health state probabilities using '$sim_stateprobs'.",
             call. = FALSE)
      }
      
      statvalmods <- switch(type,
                           costs = self$cost_models,
                           qalys = list(self$utility_model))
      
      statvalmods.name <- switch(type,
                                costs = "cost_models",
                                qalys = "utility_model")
      
      # Check number of samples
      expected.samples <- max(self$stateprobs_$sample)
      for (i in 1:length(statvalmods)){
        if (statvalmods[[i]]$params$n_samples != expected.samples){
          msg <- paste0("Number of samples in '", statvalmods.name, "' must equal to ",
                        " the number of samples in 'survival_models', which is ",
                         expected.samples)
          stop(msg, call. = FALSE)
        }
      }
      
      # Check number of states
      for (i in 1:length(statvalmods)){
        if(self$n_states != statvalmods[[i]]$data$n_states + 1){
          msg <- paste0("The number of survival models must equal the number of states in '",
                        statvalmods.name, "' - 1.")
          stop(msg, call. = FALSE)
        }
      } # loop over models
      
      stateprobs <- self$stateprobs_[state_id != self$n_states] 
      
      if (type == "costs"){
        if (is.null(names(self$cost_models))){
          type.names <- paste0("Type ", seq(1, length(self$cost_models)))
        } else{
            type.names <- names(self$cost_models)
        } # end if/else names for cost models
      } else{
        type.names <- "qalys"
      } # end if/else costs vs. qalys

      res <- data.table(C_PartSurv_sim_auc(self, stateprobs, dr, type, type.names))
      res[, state_id := state_id + 1]
      res[, sample := sample + 1]
      res[, strategy_id := strategy_id + 1]
      res[, patient_id := patient_id + 1]
      return(res[])
    }
  ),
  
  active = list(
    t_ = function(value) {
      if (missing(value)) {
        private$.t_
      } else {
        stop("'$t_' is read only", call. = FALSE)
      }
    },
    
    survival_ = function(value) {
      if (missing(value)) {
        private$.survival_
      } else {
        stop("'$survival_' is read only", call. = FALSE)
      }
    },
    
    stateprobs_ = function(value) {
      if (missing(value)) {
        private$.stateprobs_
      } else {
        stop("'$stateprobs_' is read only", call. = FALSE)
      }
    },
    
    qalys_ = function(value) {
      if (missing(value)) {
        private$.qalys_
      } else {
        stop("'$qalys_' is read only", call. = FALSE)
      }
    },
    
    costs_ = function(value) {
      if (missing(value)) {
        private$.costs_
      } else {
        stop("'$costs_' is read only", call. = FALSE)
      }
    }
    
  ),
                        
  public = list(
    survival_models = NULL,
    utility_model = NULL,
    cost_models = NULL,
    n_states = NULL,

    initialize = function(survival_models, utility_model = NULL, cost_models = NULL) {
      self$survival_models <- survival_models
      self$cost_models = cost_models
      self$utility_model = utility_model
      self$n_states <- length(self$survival_models$params) + 1
    },
    
    sim_survival = function(t){
      if (t[1] !=0){
        stop("The first element of 't' must be 0.", call. = FALSE)
      }
      if(!inherits(self$survival_models, "PartSurvCurves")){
        stop("'survival_models' must be of class 'PartSurvCurves'.")
      }
      self$survival_models$check()
      private$.survival_ <- self$survival_models$survival(t)
      private$.t_ <- t
      private$.stateprobs_ <- NULL
      invisible(self)
    },
    
    sim_stateprobs = function(){
      if(is.null(self$survival_)){
        stop("You must first simulate survival curves using '$sim_survival'.",
            call. = FALSE)
      }
      res <- C_PartSurv_sim_stateprobs(self)
      prop.cross <- res$n_crossings/nrow(res$stateprobs)
      if (prop.cross > 0){
        warning(paste0("Survival curves crossed ", prop.cross * 100, 
                       " percent of the time."),
                call. = FALSE)
      }
      stateprobs <- data.table(res$stateprobs)
      stateprobs[, state_id := state_id + 1]
      stateprobs[, sample := sample + 1]
      private$.stateprobs_ <- stateprobs[]
      invisible(self)
    },
    
    sim_qalys = function(dr = .03){
      self$utility_model$check()
      qalys <- private$sim_auc(dr, type = "qalys")
      setnames(qalys, "value", "qalys")
      private$.qalys_ <- qalys
      invisible(self)
    },
    
    sim_costs = function(dr = .03){
      if(!is.list(self$cost_models)){
        stop("'cost_models' must be a list", call. = FALSE)
      }
      for (i in 1:length(self$cost_models)){
        self$cost_models[[i]]$check()
      }
      costs <- private$sim_auc(dr, type = "costs")
      setnames(costs, "value", "costs")
      private$.costs_ <- costs
      invisible(self)
    }
  )
)