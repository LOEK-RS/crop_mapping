// Extract gee covariates of Nematode Observation Points for comparison with Hooger et al extraction



var elevation = ee.Image("USGS/GMTED2010");
var slope = ee.Terrain.slope(elevation);
var hillshade = ee.Terrain.hillshade(elevation);

var aspect = ee.Terrain.aspect(elevation);
var northness = aspect.cos();
var eastness = aspect.sin();


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



var topo_stack = elevation.rename("elevation")
  .addBands(slope)
  .addBands(hillshade)
  .addBands(northness.rename("northness"))
  .addBands(eastness.rename("eastness"));
  
  
var cov_stack = modis_stack
  .addBands(topo_stack);

var sample = ee.FeatureCollection("users/Ludwigm6/nematodes_sample");

var sampledPoints = cov_stack.sampleRegions({
  collection: sample,
  scale: 1000
});

  
Export.table.toDrive(sampledPoints)