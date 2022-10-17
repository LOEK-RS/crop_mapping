library(tidyverse)
library(sf)
library(rnaturalearth)
library(caret)
library(ranger)
library(CAST)


lucas = read.csv("data/results/lucas_gee_final1.csv")
lucas_spatial = st_read("data/raw/lucas_2018_checked_v1_2021-12-14.gpkg")
lucas = lucas |> select(all_of(c("point_id",  "survey_date", "lc1", "B2", "B3", "B4", "B8", "SCL", "correct_photos")))
lucas = lucas_spatial |> select(all_of(c("point_id", "geom"))) |>  right_join(lucas, by = "point_id")

head(lucas)



sf::sf_use_s2(FALSE)
europe = rnaturalearth::ne_countries(returnclass = "sf",continent = "Europe") |>
    st_transform(st_crs(lucas)) |> 
    select("name") |> rename(country = "name")

lucas = st_join(lucas, europe)


table(lucas$country, lucas$lc1)




lucas_train = lucas |> filter(country %in% c("Belgium", "Netherlands", "Poland", "Germany"))
lucas_test = lucas |> filter(country %in% c("Spain", "Italy", "Portugal"))

table(lucas_train$lc1)
table(lucas_test$lc1)






lucas_train = lucas_train |> st_drop_geometry()


# create cv folds based on country
folds = CAST::CreateSpacetimeFolds(x = lucas_train, spacevar = "country", k = 4, class = "lc1", seed = 1)

# train control to specify additonal model parameters (cv method)
trc = trainControl(method = "cv", index = folds$index, indexOut = folds$indexOut, number = 4, savePredictions = TRUE)

# train the model:
#- random forest from the "ranger" package
#- tuneLength = 1: no hyperparameter tuning
#- num.trees: 50 trees in the rf model
#- importance: variable importance calculation
rfmodel = caret::train(x = lucas_train |> select(all_of(c("B2", "B3", "B4", "B8"))),
                       y = lucas_train |> pull("lc1"),
                       method = "ranger",
                       tuneLength = 1,
                       trControl = trc,
                       num.trees = 50,
                       importance = "impurity")

rfmodel

# accuracy assessment over all cv folds
CAST::global_validation(rfmodel)

# predict on other countries
lucas_test$validation = predict(rfmodel, lucas_test |> st_drop_geometry())

# confusion matrix of prediction
caret::confusionMatrix(as.factor(lucas_test$lc1), lucas_test$validation)