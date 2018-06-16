/* blah */

// initialise timedimension and associated control + player
// (but don't attached to the map yet)
var td = new L.TimeDimension({
  timeInterval: '1939-07-01T00:00:00.000Z/2013-12-01T00:00:00.000Z',
  period: 'P1M'
});
var td_player = new L.TimeDimension.Player({
  buffer: 5,     // control to taste
  loop: true,
  transitionTime: 80,
  startOver: false
}, td);
var td_control = new L.Control.TimeDimension({
  position: 'bottomleft',
  speedSlider: false,
  limitSliders: false,
  backwardButton: false,
  forwardButton: false,
  player: td_player
});

// initialise map; attach timedimension and its control
var mymap = L.map('map', {
  center: [-27, 134],     // lat, lon
  zoom: 4,
  zoomSnap: 0.5,             // defualt 1
  crs: L.CRS.EPSG4326,    // need a matching basemap!
  zoomControl: false,
  attributionControl: false, // it's on the about screen instead
  doubleClickZoom: false,
  boxZoom: false,
  touchZoom: false,
  scrollWheelZoom: false,
  dragging: false,
  keyboard: false     // if this causes problems, use keyboardDelta: 0 instead
});
// mymap.zoomControl.setPosition('topleft');
mymap.timeDimension = td;
mymap.addControl(td_control);

// add base tile layer
var base_tiles = L.tileLayer(
  'https://tile.gbif.org/4326/omt/{z}/{x}/{y}@1x.png?style=gbif-dark',
  {
    subdomains: 'abcd',
    minZoom: 1,
    maxZoom: 16,
    ext: 'png',
    updateWhenIdle: false
  }).addTo(mymap);

// base options for all geoserver wms requests
var geoserver_base = 'https://climdex.org/geoserver/showcase/wms?',
    hb_layer = L.timeDimension.layer.wms(
      L.tileLayer.wms(geoserver_base,
        {
          service: 'WMS',
          version: '1.1.0',
          request: 'GetMap',
          layers: 'hb_tn_gt20_mth',
          // env: 'low:0;high:31',
          srs: 'EPSG:4326',
          format: 'image/png',
          // className: 'blend_multiply',
          transparent: true,
          updateWhenIdle: false
        }),
      { cache: 894 }).addTo(mymap);
      
// set initial view (and ensure it recalculates on container resize)
function reset_view() {
  var map_size = mymap.getSize(),
      aspect = map_size.x / (map_size.y);

  mymap.flyToBounds([[-11, 113], [-44, 154]],
  {
    paddingTopLeft: aspect <= 1.25 ?                   // max aspect ratio
      [10,              ((map_size.y) / 2)] :           // portrait padding
      [map_size.x / 2, 10],                             // landscape padding
    paddingBottomRight: [10, 10],
    animate: false
  });
}
reset_view();
mymap.on('resize', reset_view);

/* chart setup */

// when the chart's loaded...
var chart = document.getElementById('ts_chart');
chart.addEventListener('load', function() {
  
  // allow the chart to be updated in response to the time dimension
  chart_loaded = true;

  var frame_count = hb_layer.options.cache;

  // prefetch the frames, and get things going when they're all here
  function _prefetch_animation() {
    td.off('timeload', _prefetch_animation, this);

    /* prefetch the animation frames, then play when we have them */
    hb_layer.on('timeload', _check_to_play, this);
    console.log('Fetching ' + frame_count + ' frames before starting; ' +
      td.getNumberNextTimesReady(1, frame_count, true) +
      ' already available');
    td.prepareNextTimes(1, frame_count, true);
  }

  function _check_to_play() {
    if (td.getNumberNextTimesReady(1, frame_count, true) < frame_count) {
      // still waiting
      console.log('Waiting (' +
        td.getNumberNextTimesReady(1, frame_count, true) + ' of ' +
        frame_count + ' frames ready)')
    } else {
      // ready!
      // console.log('let\'s go');
      hb_layer.off('timeload', _check_to_play, this);
      // td.off('timeload', preload_storybit_frames, this);
      td.setCurrentTimeIndex(0);
      td_player.start();
    }
  }

  // set the timedimension to first frame
  td.on('timeload', _prefetch_animation, this);
  td.setCurrentTimeIndex(0);
});