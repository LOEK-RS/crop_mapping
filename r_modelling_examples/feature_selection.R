library(dplyr)
library(sf)


data = read.csv("data/final_Extract_train.csv")
head(data)


# clean data
data = data |> filter(correct_photos == 4)


# remove unnecessary cols and save predictor + response names 
keep_cols = names(data)
keep_cols = keep_cols[c(-1, -33:-41, -43:-54)]

predictors = keep_cols[1:30]
response = "lc1"

data = data |> select(all_of(keep_cols))


# attach spatial information for CV setup
lucas_spatial = st_read("data/raw/lucas_2018_checked_v1_2021-12-14.gpkg")
lucas = lucas_spatial |> select(all_of(c("point_id", "geom"))) |>  right_join(data, by = "point_id")

sf::sf_use_s2(FALSE)
europe = rnaturalearth::ne_countries(returnclass = "sf",continent = "Europe") |>
    st_transform(st_crs(lucas)) |> 
    select("name") |> rename(country = "name")

lucas = st_join(lucas, europe)

# southern countries for test, northern for train

lucas_test = lucas |> filter(country %in% c("Spain", "Italy", "Portugal", "Greece", "Bulgaria"))
lucas_train = lucas |> filter(!(country %in% c("Spain", "Italy", "Portugal", "Greece", "Bulgaria")))

# remove countries with only few points
lucas_train = lucas_train |> filter(!(country %in% c("Belarus", "Croatia", "Moldova", "Russia", "Switzerland", "Ukraine")))




# combine regions for folds

# Ireland, United Kingdom
# France
# Germany, Netherlands, Belgium, Luxembourg
# Denmark, Sweden, Finland, Estonia, Latvia, Lithuania
# Poland
# Czech Rep., Slovakia, Slovenia, Hungary, Romania, Austria

fold_lut = data.frame(country = c("Ireland", "United Kingdom", "France",
                                  "Germany", "Netherlands", "Belgium", "Luxembourg",
                                  "Denmark", "Sweden", "Finland", "Estonia", "Latvia", "Lithuania",
                                  "Poland",
                                  "Czech Rep.", "Slovakia", "Slovenia", "Hungary", "Romania", "Austria"),
                      fold = paste0("Fold", c(1,1,1,2,2,2,2,3,3,3,3,3,3,4,5,5,5,5,5,5)))


lucas_train = left_join(lucas_train, fold_lut)

# visualize folds
plot(lucas_test[,"country"])
table(lucas_train$fold, lucas_train$lc1)



lucas_train = lucas_train |> st_drop_geometry()
lucas_train

library(CAST)
library(caret)
library(ranger)

folds = CAST::CreateSpacetimeFolds(x = lucas_train, spacevar = "country", k = 5, class = "lc1")


# train control to specify additonal model parameters (cv method)
trc = trainControl(method = "cv", index = folds$index, indexOut = folds$indexOut, number = 5, savePredictions = TRUE)

# train the model:
#- random forest from the "ranger" package
#- tuneLength = 1: no hyperparameter tuning
#- num.trees: 50 trees in the rf model
#- importance: variable importance calculation


tg = expand.grid(splitrule = "gini", mtry = 2, min.node.size = 1)


# model using all 30 predictors
rfmodel = caret::train(x = lucas_train |> select(all_of(predictors)),
                       y = lucas_train |> pull("lc1"),
                       method = "ranger",
                       tuneGrid = tg,
                       trControl = trc,
                       num.trees = 50,
                       importance = "impurity")

# model with feature selection --> resulting in 8 predcitors
feature_selection = CAST::ffs(predictors = lucas_train |> select(all_of(predictors)),
                              response = lucas_train |> pull("lc1"),
                              method = "ranger",
                              tuneGrid = tg,
                              trControl = trc,
                              num.trees = 50,
                              importance = "impurity")


feature_selection
rfmodel

# save model results
saveRDS(feature_selection, "r_modelling_examples/ffs_model.RDS")
saveRDS(rfmodel, "r_modelling_examples/rfmodel.RDS")

# load results from file
ffsmodel <- readRDS("r_modelling_examples/ffs_model.RDS")



# predict on test data
lucas_test$prediction = predict(feature_selection, lucas_test |> st_drop_geometry())
lucas_test$prediction_all = predict(rfmodel, lucas_test |> st_drop_geometry())

# confusion matrix
confusionMatrix(table(lucas_test$lc1, lucas_test$prediction))
confusionMatrix(table(lucas_test$lc1, lucas_test$prediction_all))



