


var modis_vegetation = ee.ImageCollection('MODIS/006/MYD13Q1')
  .filterDate('2013-01-01', '2017-12-31')
  .select(['NDVI', 'EVI'])
  .mean();
  
var modis_gpp = ee.ImageCollection('MODIS/055/MOD17A3')
  .filterDate('2010-01-01', '2014-12-31')
  .select(['Gpp', 'Npp'])
  .mean();
  

var modis_bands = ee.ImageCollection('MODIS/MCD43A4')
  .filterDate('2012-01-01', '2016-12-31')
  .mean();
  
  
  
var modis_stack = modis_vegetation
  .addBands(modis_gpp)
  .addBands(modis_bands);



// Download tiles in a 10 degree grid
var grid = ee.FeatureCollection("users/Ludwigm6/grid_global");
var list= grid.toList(1000);


for (var i = 0; i < 300; i++){
  
  
  var aoi = ee.Feature(list.get(i)).geometry();
  var aoi_id = ee.Feature(list.get(i)).get('id');
  
  
  Export.image.toDrive({
  image: modis_stack,
  description: 'modis_' + String(i),
  folder: "gee",
  scale: 1000,
  region: aoi
});
 
  
  
}