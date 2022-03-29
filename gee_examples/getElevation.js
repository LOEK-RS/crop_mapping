


// topography

var elevation = ee.Image("USGS/GMTED2010");
var slope = ee.Terrain.slope(elevation);
var hillshade = ee.Terrain.hillshade(elevation);
var aspect = ee.Terrain.aspect(elevation);
var northness = aspect.cos();
var eastness = aspect.sin();




var topo_stack = elevation.rename("elevation")
  .addBands(slope)
  .addBands(hillshade)
  .addBands(aspect)
  .addBands(northness.rename("northness"))
  .addBands(eastness.rename("eastness"));

  
  
// Download tiles in a 10 degree grid
var grid = ee.FeatureCollection("users/Ludwigm6/grid_global");
var list= grid.toList(1000);


for (var i = 0; i < 300; i++){
  
  
  var aoi = ee.Feature(list.get(i)).geometry();
  var aoi_id = ee.Feature(list.get(i)).get('id');
  
  
  Export.image.toDrive({
  image: topo_stack.toDouble(),
  description: 'topo_' + String(i),
  folder: "gee",
  scale: 1000,
  region: aoi
});
 
  
  
}